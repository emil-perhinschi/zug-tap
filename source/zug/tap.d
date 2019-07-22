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
    private string test_name = "";

    private bool have_plan = false;
    private int tests_planned = 0;
    private TapData[] tests_data;
    private int tests_count = 0;
    private int tests_passed = 0;
    private int tests_failed = 0;
    private string cache = ""; // cache debug output here ... probably
    private uint indentation = 0;

    private ProcessPipes consumer;
    private bool use_consumer = false;

    private bool debug_enabled = false;
    private bool print_messages = true;

    // skip tests and add them to tests_skipped until true
    private bool skipping = false;
    private int tests_skipped;

    this(string test_name)
    {
        this.test_name = test_name;
    }

    void set_consumer( ProcessPipes consumer) 
    {
        this.consumer = consumer;           
        this.use_consumer = true;
    }

    void enable_consumer()
    {
        this.use_consumer = true;
    }

    void disable_consumer()
    {
        this.use_consumer = false;
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
        auto final_message = indent_string ~ message.join(" ");
        if (this.verbose())
        {
            writeln(final_message);
        }

        if (this.use_consumer) {
            this.consumer.stdin.writeln(final_message);
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
        this.write("1.." ~ to!string(this.tests_planned) );
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

        if (this.use_consumer) {
            this.consumer.stdin.flush();
            this.consumer.stdin.close();
            wait(this.consumer.pid);
            this.disable_consumer();
        }

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
            this.write("1.." ~ to!string(this.tests_count) );
            return this.tests_failed == 0;
        }

    }

    void report() {
        // dfmt off 
        this.write(
            "Test: " ~ this.test_name ~ " = ",
            to!string(tests_passed), "tests passed;", 
            to!string(tests_failed), "tests failed"
        );
        
        this.write(
            "Planned:", to!string(this.tests_planned), 
            "; completed:", to!string(this.tests_count), 
            "; skipped:", to!string(this.tests_skipped),
            "\n\n");
        // dfmt on
    }

    void diag(string message)
    {
        auto lines = splitLines(message).map!(a => "  #" ~ stripRight(a)).join("\n");

        this.write("  #DIAGNOSTIC: ", "\n", lines);
        this.tests_data ~= TapData(TapDataType.diagnostic, true, message);
    }

    void note(string message)
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
            this.diag(e.msg);
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

    // alias SubtestCoderef = bool delegate();
    // bool subtest(string label, SubtestCoderef subtest_callback)
    // {
    //     this.write("# subtest: ", label);
    //     sub_tap.indentation = tap.indentation + 2;
    //     auto subtest_result = subtest_callback();
    //     this.ok(subtest_result, label);
    //     return subtest_result;
    // }
}

unittest
{
    {
        auto tap = Tap("first unittest block");
        tap.verbose(true);
        assert(tap.verbose() == true);
        tap.plan(10);
        assert(tap.plan() == 10);
        assert(!tap.ok(false, "should fail"));
        assert(tap.ok(true, "should pass"));
        assert(!tap.ok(delegate bool() { return false; }, "should fail"));
        assert(tap.ok(delegate bool() { return true; }, "should pass"));
        assert(tap.results().length == 4);
        assert(!tap.done_testing());
        tap.report();
    }

    { // test skipping
        auto tap = Tap("second unittest block");
        tap.verbose(true);
        assert(tap.verbose() == true);
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
        tap.report();
    }

    // { // subtests
    //     auto tap = Tap("third unittest block with subtest");
    //     tap.plan(2);
    //     // dfmt off
    //     tap.ok(
    //         tap.subtest(
    //             "this is a subtest with 3 tests", 
    //             delegate bool () {
    //                 auto sub_tap = Tap("first subtest");
    //                 sub_tap.indentation = tap.indentation + 2;
    //                 sub_tap.plan(3); 
    //                 sub_tap.ok(true, "should pass");
    //                 sub_tap.ok(!false, "should fail"); 
    //                 sub_tap.ok(2 == 2, "should pass");
    //                 return sub_tap.done_testing();
    //             }
    //         ),
    //         "subtest executed and returned true"
    //     );
    //     // dfmt on
    //     tap.ok(true, "true after subtests");
    //     tap.done_testing();
    //     tap.report();
    // }

    { // test consumer tappy
        import std.file;
        import std.process;

        string path_to_tappy = "/usr/bin/tappy";
        auto tap = Tap("test with pipe to tappy");
        tap.verbose(false);

        if ( path_to_tappy.exists && path_to_tappy.isFile ) {
            auto pipe = pipeProcess(path_to_tappy, Redirect.stdin);
            tap.set_consumer(pipe);
        }
        else {
            tap.verbose(true);
            tap.skip("tappy not found, skipping the consumer pipe tests");
        }

        tap.plan(6);
        tap.ok(true, "should pass 1");
        tap.ok(true, "should pass 2");
        tap.ok(true, "should pass 3");
        tap.ok(true, "should pass 4");
        tap.ok(true, "should pass 5");
        tap.ok(false, "should fail 6");
        tap.done_testing();
        assert(tap.tests_passed == 5, "five tests passed");
        assert(tap.tests_failed == 1, "one test failed");
        assert(tap.results().length == 6, "six tests ran");

        // not calling report(), let tappy do the reporting
        // tap.verbose(true);
        // tap.report();
    }
}
