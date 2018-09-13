module zug.tap;

import zug.util;
import std.stdio;
import std.conv;
import std.string;
import std.algorithm;
import std.process;

// redirect stdout to file
// https://www.tutorialspoint.com/c_standard_library/c_function_freopen.htm 
// https://dlang.org/library/core/stdc/stdio.html

// http://stackoverflow.com/questions/37760630/redirect-stdout-stderr-to-function-in-c

// ***** good one I think ***** http://stackoverflow.com/questions/584868/rerouting-stdin-and-stdout-from-c

// redirect stdout/stderr to file from within D
// http://forum.dlang.org/post/cbmdojwoebqdirbapoev@forum.dlang.org

// this looks interesting
// https://dlang.org/library/std/stdio/file.html

// my question on forum http://forum.dlang.org/post/cbhzvymjnribmbpccjrx@forum.dlang.org

// the old std.stream
// /home/emilper/.dub/packages/undead-1.0.6/undead/src/undead/stream.d

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

// TODO: look into Test Anything Protocol http://testanything.org/
class Tap {

    private bool verbose = true;
    private int planned_tests;
    private TapData[] results;
    private int tests_count = 0;
    private string cache = "";
    private bool debug_enabled = false;
    this() {}

    this(bool verbose, int plan) {
        this.verbose = verbose;
        this.planned_tests = plan;
        this.debug_enabled = std.process.environment.get("DEBUG") == "1" ? true : false;
    }

    void done_testing() {
        string[string] summary;
        int tests_succeeded = 0;
        int tests_failed = 0;
        foreach (TapData result; this.results) {
            if(result.data_type != TapDataType.test_result) {
                continue;
            }
            
            if(result.success) {
                tests_succeeded++;
            }
            else {
                tests_failed++;
            }
        }
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





