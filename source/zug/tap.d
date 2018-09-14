module zug.tap;

import zug.util;
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

// need to keep the diagnostics, the notes, the results etc. in order
struct TapData {
    TapDataType data_type; 
    bool success;
    string message;
}


class Tap {

    private bool print_each_result = true;
    private int planned_tests;
    private TapData[] results;
    private int tests_count = 0;
    private string cache = "";
    private bool debug_enabled = false;

    this() {
        this.debug_enabled = std.process.environment.get("DEBUG") == "1" ? true : false;
    }

    void verbose(bool verbose) { this.print_each_result = verbose; }
    bool verbose()             { return this.print_each_result; }

    void plan(int plan )       { this.planned_tests = plan; }
    int plan()                 { return this.planned_tests ? this.planned_tests : 0; }

    bool done_testing() {
        string[string] summary;
        int tests_passed = 0;
        int tests_failed = 0;
        foreach (TapData result; this.results) {
            if(result.data_type != TapDataType.test_result) {
                continue;
            }
            
            if (result.success) {
                tests_passed++;
            }
            else {
                tests_failed++;
            }
        }

        if (this.debug_enabled) {
            writeln(tests_passed, " tests passed; ", tests_failed, " tests failed");
            writeln("Planned ", this.planned_tests,  "; completed ", this.tests_count);
        }

        return this.planned_tests == tests_passed;
    }
    
    void add_result(bool success, string message) {
        this.tests_count++;
        if(this.verbose) {
            writeln( ( success ? "ok" : "not ok")
                    ~ " " ~ to!string(this.tests_count) ~ " " ~ message);
        }
        this.results ~= TapData(TapDataType.test_result, success, message);
    }
    
    void add_diagnostic(string message) {
        if(this.verbose) {
            auto lines = splitLines(message).map!(a => "  #" ~ stripRight(a)).join("\n");
            writeln( "  #DIAGNOSTIC: " ~ "\n" ~ lines );
        }
        
        this.results ~= TapData(TapDataType.diagnostic, true, message);
    }
    
    void add_note(string message) {
        if(this.verbose) {
            writeln( "#NOTE: " ~ " " ~ message);
        }
        this.results ~= TapData(TapDataType.note, true, message);
    }


    void ok(bool delegate () test, string message) {
        try {
            bool result = test();
            this.add_result(result, message);
        } catch (Exception e) {
            this.add_diagnostic(e.msg);
            this.add_result(false, message);
        }
    }

    void ok(bool is_true, string message ) {
        this.add_result(is_true, message);
    }

    void do_debug(string message) {
        if (this.debug_enabled) {
            stderr.writeln("DEBUG: " ~ message);
        }
    }

    void skip() {
        write_debug("TODO");
    }
    

    void start_subtest() {
        write_debug("TODO");
    }
}

unittest {
    auto tap = new Tap();
    auto test_the_tap = new Tap();
    tap.verbose(true);
    tap.plan(10);
    tap.ok(false, "should fail");
    tap.ok(true, "should pass");
    tap.ok(delegate bool () { return false; }, "should fail");
    tap.ok(delegate bool () { return true; },  "should pass");
    test_the_tap.ok(tap.done_testing(), "tap.done_testing should report errors");
}



