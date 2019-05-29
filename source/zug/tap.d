module zug.tap;

import std.stdio;
import std.conv;
import std.string;
import std.algorithm;
import std.process;

enum TapDataType
{
    test_result,
    diagnostic,
    note
};

// need to keep the diagnostics, the notes, the results etc. in order
struct TapData
{
    TapDataType data_type;
    bool success;
    string message;
}

struct Tap
{
    private bool have_plan = false;
    private int tests_planned;
    private TapData[] tests_data;
    private int tests_count;
    private int tests_passed;
    private int tests_failed;
    private string cache = ""; // cache debug output here ... probably
    private uint indentation = 0;

    private bool debug_enabled = false;
    private bool print_messages = true;

    // skip tests and add them to tests_skipped until true
    private bool skipping = false;
    private int tests_skipped;

    this(bool verbose)
    {
        this.print_messages = verbose;
        if (this.verbose())
        {
            this.debug_enabled = std.process.environment.get("DEBUG") == "1" ? true : false;
        }
    }

    void verbose(bool verbose)
    {
        this.print_messages = verbose;
    }

    bool verbose()
    {
        return this.print_messages;
    }

    void write(string[] message...)
    {
        import std.array: replicate;
        
        string[] result;
        // dfmt off
        auto indent_string = " ".replicate(this.indentation);
        // dftm on
        if (this.verbose())
        {
            writeln(indent_string, message.join(" "));
        }
    }

    void warn(string[] message...)
    {
        if (this.debug_enabled)
        {
            stderr.writeln(message.join(" "));
        }
    }

    void plan(int plan)
    {
        this.tests_planned = plan;
        this.have_plan = true;
    }

    int plan()
    {
        return this.tests_planned ? this.tests_planned : 0;
    }

    TapData[] results()
    {
        return this.tests_data;
    }

    void add_result(bool success, string message)
    {
        this.tests_count++;
        this.write( (success ? "ok" : "not ok"), to!string(this.tests_count), message);
        this.tests_data ~= TapData(TapDataType.test_result, success, message);
    }

    bool done_testing()
    {
        string[string] summary;

        foreach (TapData result; this.tests_data)
        {
            // not all results are tests results, some are notes or debug or something else
            if (result.data_type != TapDataType.test_result)
            {
                continue;
            }

            if (result.success)
            {
                this.tests_passed++;
            }
            else
            {
                this.tests_failed++;
            }
        }

        if (this.have_plan) 
        {
            return this.tests_failed == 0 && this.tests_count == this.tests_planned;
        }
        else 
        {
            return this.tests_failed == 0;
        }
    }

    void report() {
        // dfmt off 
        this.write(
            to!string(tests_passed), "tests passed;", 
            to!string(tests_failed), "tests failed"
        );
        
        this.write(
            "Planned:", to!string(this.tests_planned), 
            "; completed:", to!string(this.tests_count), 
            "; skipped:", to!string(this.tests_skipped));
        // dfmt on
    }

    void add_diagnostic(string message)
    {
        auto lines = splitLines(message).map!(a => "  #" ~ stripRight(a)).join("\n");

        this.write("  #DIAGNOSTIC: ", "\n", lines);
        this.tests_data ~= TapData(TapDataType.diagnostic, true, message);
    }

    void add_note(string message)
    {
        this.write("#NOTE: ", message);
        this.tests_data ~= TapData(TapDataType.note, true, message);
    }

    bool ok(bool delegate() test, string message)
    {
        if (this.skipping)
        {
            this.tests_skipped += 1;
            return true;
        }

        bool result;
        try
        {
            result = test();
        }
        catch (Exception e)
        {
            result = false;
            this.add_diagnostic(e.msg);
        }
        this.add_result(result, message);
        return result;
    }

    bool ok(bool is_true, string message = "")
    {
        if (this.skipping)
        {
            this.tests_skipped += 1;
            return true;
        }

        this.add_result(is_true, message);
        return is_true;
    }

    void do_debug(string message)
    {
        if (this.debug_enabled)
        {
            stderr.writeln("DEBUG: " ~ message);
        }
    }

    void skip(string message)
    {
        this.skipping = true;
        this.write("# skipping tests: ", message);
    }

    void resume(string message)
    {
        this.skipping = false;
        this.write("# resuming tests: ", message);
    }

    alias SubtestCoderef = bool delegate();
    bool subtest(string label, SubtestCoderef subtest_callback)
    {
        this.write("# subtest: ", label);
        return subtest_callback();
    }
}

unittest
{
    bool talk_to_me = std.process.environment.get("DEBUG") == "1" ? true : false;
    {
        auto tap = Tap(talk_to_me);
        assert(tap.verbose() == talk_to_me);
        tap.plan(10);
        assert(tap.plan() == 10);
        assert(!tap.ok(false, "should fail"));
        assert(tap.ok(true, "should pass"));
        assert(!tap.ok(delegate bool() { return false; }, "should fail"));
        assert(tap.ok(delegate bool() { return true; }, "should pass"));
        assert(tap.results().length == 4);
        assert(!tap.done_testing());
    }

    { // test skipping
        auto tap = Tap(talk_to_me);
        assert(tap.verbose() == talk_to_me);
        assert(tap.ok(true, "should pass"));
        assert(tap.ok(true, "should pass"));
        tap.skip("skipping two out of six tests");
        assert(tap.ok(true, "should pass"));
        assert(tap.ok(true, "should pass"));
        tap.resume("skipped two tests out of six, resuming");
        assert(tap.ok(true, "should pass"));
        assert(tap.ok(true, "should pass"));
        assert(tap.results().length == 4);
        assert(tap.tests_skipped == 2);
        assert(tap.done_testing());
    }

    { // subtests
        auto tap = Tap(talk_to_me);
        tap.plan(2);
        // dfmt off
        tap.ok(
            tap.subtest(
                "this is a subtest with 3 tests", 
                delegate bool () {
                    auto sub_tap = Tap(talk_to_me);
                    sub_tap.indentation = tap.indentation + 2;
                    sub_tap.plan(3); 
                    sub_tap.ok(true, "should pass");
                    sub_tap.ok(!false, "should fail"); 
                    sub_tap.ok(2 == 2, "should pass");
                    return sub_tap.done_testing();
                }
            )
        );
        // dfmt on
        tap.ok(true, "true after subtests");
        tap.done_testing();
    }

/*

TODO tests: 
 - plan exists and result is based on passed tests matching planned tests
 - plan does not exist and final result is based on failed tests being equal to 0
 - 

TODO code: 
 - indentation for subtests (should I go beyond one level of subtests, is there any use in it ? )
 - get test final report as a struct
 - get test final report as json/csv
 

TODO think about it: 
 - do something like prove from perl 
 - how would I do standalone tests that do not get compiled in the production version but can be executed when running "dub test" ? 
    Maybe have the tests in a separate source/t/ folder and be imported in a unittest block in the library file ?
*/
}
