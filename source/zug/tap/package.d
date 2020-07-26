module zug.tap;

import std.stdio;
import std.conv;
import std.string;
import std.algorithm;
import std.process;

enum TapDataType {
    test_result,
    diagnostic,
    note
};

/// needed to keep the diagnostics, the notes, the results etc. in order
struct TapData {
    TapDataType data_type;
    bool success;
    string message;
}

/**
struct Tap keeps the test data and gives access to the test methods
*/
struct Tap {
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

    this(string test_name) {
        this.test_name = test_name;
    }

    void set_consumer(ProcessPipes consumer) {
        this.consumer = consumer;
        this.use_consumer = true;
    }


    void enable_consumer() {
        this.use_consumer = true;
    }

    void disable_consumer() {
        this.use_consumer = false;
    }

    void verbose(bool verbose) {
        this.print_messages = verbose;
    }

    bool verbose() {
        return this.print_messages;
    }

    void write(string[] message...) {
        import std.array : replicate;

        string[] result;
        // dfmt off
        auto indent_string = " ".replicate(this.indentation);
        // dftm on
        auto final_message = indent_string ~ message.join(" ");
        if (this.verbose()) {
            writeln(final_message);
        }

        if (this.use_consumer) {
            this.consumer.stdin.writeln(final_message);
        }
    }

    void warn(string[] message...) {
        if (this.debug_enabled) {
            stderr.writeln(message.join(" "));
        }
    }

    /**
        set the number of planned tests
    */
    void plan(int plan) {
        this.tests_planned = plan;
        this.have_plan = true;
        this.write("1.." ~ to!string(this.tests_planned));
    }

    /**
        get the number of planned tests
    */
    int plan() {
        return this.tests_planned ? this.tests_planned : 0;
    }


    /**
        get the data for the tests ran
    */
    TapData[] results() {
        return this.tests_data;
    }


    void add_result(bool success, string message) {
        this.tests_count++;
        this.write((success ? "ok" : "not ok"), to!string(this.tests_count), message);
        this.tests_data ~= TapData(TapDataType.test_result, success, message);
    }

    /**
        Finish testing, do the accounting, print the number of tests ran. Does not take any argument.
        After this you can run `report()`.

        Returns `true` if all tests failed, else returns `false`
    */
    bool done_testing() {

        if (this.use_consumer) {
            this.consumer.stdin.flush();
            this.consumer.stdin.close();
            wait(this.consumer.pid);
            this.disable_consumer();
        }

        string[string] summary;

        foreach (TapData result; this.tests_data) {
            // not all results are tests results, some are notes or debug or something else
            if (result.data_type != TapDataType.test_result) {
                continue;
            }

            if (result.success) {
                this.tests_passed++;
            } else {
                this.tests_failed++;
            }
        }

        if (this.have_plan) {
            return this.tests_failed == 0 && this.tests_count == this.tests_planned;
        } else {
            this.write("1.." ~ to!string(this.tests_count));
            return this.tests_failed == 0;
        }

    }

    /**
    prints the detailed info about the test results.

    */
    void report() {
        // dfmt off
        this.write(
                "Test: " ~ this.test_name ~ " = ",
                to!string(this.tests_passed), "tests passed;",
                to!string(this.tests_failed), "tests failed");

        this.write(
                "Planned:", to!string(this.tests_planned),
                "; completed:", to!string(this.tests_count),
                "; skipped:", to!string(this.tests_skipped),
                "\n\n");
        // dfmt on
    }

    /**
        Print a diagnostic message and add it to the test data.

        It will be printed regardless of what `verbose` is set to.
    */
    void diag(string message) {
        auto lines = splitLines(message).map!(a => "  #" ~ stripRight(a)).join("\n");
        auto old_verbose = this.verbose;
        // diagnostics always get printed
        this.verbose(true);
        this.write("  #DIAGNOSTIC: ", "\n", lines);
        this.verbose(old_verbose);
        this.tests_data ~= TapData(TapDataType.diagnostic, true, message);
    }

    /**
        Print a note if `verbose` is set to `true`.
    */
    void note(string message) {
        this.write("#NOTE: ", message);
        this.tests_data ~= TapData(TapDataType.note, true, message);
    }

    /**
        prints "ok" or "not ok" depending if the test succeeds or fails

        Params:
            test = delegate, should return a boolean
            message = string, optional
    */
    bool ok(bool delegate() test, string message = "") {
        if (this.skipping) {
            this.tests_skipped += 1;
            return true;
        }

        bool result;
        try {
            result = test();
        } catch (Exception e) {
            result = false;
            this.diag(e.msg);
        }
        this.add_result(result, message);
        return result;
    }

    /**
        prints "ok" or "not ok" depending if the test succeeds or fails

        Params:
            test = boolean
            message = string, optional
    */
    bool ok(bool is_true, string message = "") {
        if (this.skipping) {
            this.tests_skipped += 1;
            return true;
        }

        this.add_result(is_true, message);
        return is_true;
    }

    /**
        write a debugging message to STDERR if `debug_enabled` is `true`
    */
    void do_debug(string message) {
        if (this.debug_enabled) {
            stderr.writeln("DEBUG: " ~ message);
        }
    }

    /**
        Sets `skipping` to `true` which will cause tests to be skipped; until you run `resume` no tests will be executed
    */
    void skip(string message) {
        this.skipping = true;
        this.write("# skipping tests: ", message);
    }

    /**
        Sets `skipping` to `false`: as long as it is `false` the result of the tests will be recorded or the test callbacks will be executed;
    */
    void resume(string message) {
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

unittest {
    {
        auto tap = Tap("first unittest block");
        tap.verbose(true);
        assert(tap.verbose() == true);
        tap.plan(10);
        assert(tap.plan() == 10);
        assert(!tap.ok(false, "should fail"));
        assert(tap.ok(true, "should pass"));
        assert(!tap.ok(delegate bool() {
                return false;
            }, "should fail"));
        assert(tap.ok(delegate bool() {
                return true;
            }, "should pass"));
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

    { // test consumer tappy
        import std.file;
        import std.process;

        string path_to_tappy = "/usr/bin/tappy";
        auto tap = Tap("test with pipe to tappy");
        tap.verbose(false);

        if (path_to_tappy.exists && path_to_tappy.isFile) {
            auto pipe = pipeProcess(path_to_tappy, Redirect.stdin);
            tap.set_consumer(pipe);
        } else {
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

    // exercise note() and diag() ... TODO how do I test this ? need to capture STDOUT somehow
    {
        auto tap = Tap("exercise note() and diag()");
        tap.verbose(false);
        tap.plan(1);
        tap.note("ERROR: this is a note, should not see it now because verbose is false");
        tap.diag("this is a diagnostic, should see it no matter what verbose is set to");
        tap.verbose(true);
        tap.note("this is another note, should see it");
        tap.ok(true);
        tap.done_testing();
    }
}
