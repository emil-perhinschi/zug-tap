module zug.tap.consumer;

import zug.tap;

string[] read_dir(string source_dir, bool verbose = false, bool do_debug = false) {
    import std.stdio : writeln;
    import std.file : DirEntry, dirEntries, SpanMode;

    import std.array : array;
    import std.path : baseName;
    import std.string : indexOf;
    import std.regex : match;

    string[] files;

    auto entries = dirEntries(source_dir, "*", SpanMode.shallow);
    foreach (DirEntry entry; entries) {
        if (entry.isDir) {
            if (entry.name.baseName.indexOf('.') == 0) {
                if (do_debug) {
                    writeln("HIDDEN DIR found ", entry.name);
                }
                continue;
            }
            if (do_debug) {
                writeln("DIR found ", entry.name);
            }
            files ~= read_dir(entry.name);
        } else {
            if (!entry.name.match(r"\.d$")) {
                if (do_debug) {
                    writeln("NOT A .D FILE", entry.name); 
                }
                continue;
            }

            files ~= entry.name;
        }
    }

    return files;
}

string[] read_test_files(string test_dir, bool verbose = false, bool do_debug = false) {
    import std.stdio : writeln;
    import std.file : dirEntries, SpanMode;
    import std.algorithm : sort;
    import std.array : array;

    // TODO: check dir exists, etc.

    auto files = dirEntries(test_dir, "*.d", SpanMode.shallow);
    auto file_paths = array(files);

    if (do_debug) { writeln("file paths ", file_paths); }

    return ["abc"];
}

struct TestResults {
    int passed = 0; // passed tests
    int failed = 0; // failed tests
    int planned = 0; // planned tests;
    bool done_testing = false; // was there a plan printed and were all the planned tests run
}

TestResults run_test(string test, bool verbose = false, bool do_debug = false) {
    import std.stdio : writeln, writefln;
    import std.process : pipeProcess, Redirect, wait;
    import std.regex : ctRegex, match;
    import std.uni : toLower;
    import std.conv: to;

    TestResults raw_test_data;

    if (verbose) { writeln("Running ", test); }

    auto processPipe = pipeProcess(["/usr/bin/dub", "--single", test],
            Redirect.stdout | Redirect.stderr);
    wait(processPipe.pid);

    if (do_debug) { writeln("ran ", test, " looking at output"); }

    auto plan = ctRegex!(`^\s*(\d+)\.\.(\d+)\s*`, "i");
    auto ok = ctRegex!(`^\s*ok\s(\d+)\s+(.*)`); 
    auto not_ok = ctRegex!(`^\s*not ok\s(\d+)\s+(.*)`);
    auto diagnostic = ctRegex!(`^\s*#diagnostic:`);
    auto note = ctRegex!(`^\s*#note:`);
    auto comment = ctRegex!(`^\s*#(.*)`);

    int tests_ran = 0;
    foreach (line; processPipe.stdout.byLine) {
        if (auto matched = line.match(plan)) {
            int planned = matched.front[2].to!int;
            if (verbose) { writeln("1..", planned ); }
            raw_test_data.planned = planned;
        } else if (auto matched = line.match(ok)) {
            tests_ran++;
            if (verbose) { writeln("ok ", tests_ran, " ",matched.front[2]); }
            raw_test_data.passed++;
        } else if (auto matched = line.match(not_ok)) {
            tests_ran++;
            if (verbose) { writeln("not ok ", tests_ran, " ", matched.front[2]); }
            raw_test_data.failed++;
        }
        // TODO later
        // } else if (auto matched = line.match(diagnostic)) {
        //     debug writeln("+++++++ ", matched);
        //     debug writeln("DIAGNOSTIC: ", line);
        // } else if (auto matched = line.match(note)) {
        //     debug writeln("+++++++ ", matched);
        //     debug writeln("NOTE: ", line);
        // } else if (auto matched = line.match(comment)) {
        //     debug writeln("+++++++ ", matched);
        //     debug writeln("COMMENT: ", line);
        // } else {
        //     debug writeln("DON'T KNOW: ", line);
        // }
    }

    if (raw_test_data.failed + raw_test_data.passed == raw_test_data.planned) {
        raw_test_data.done_testing = true;
    }
    if (do_debug) { writeln(test, raw_test_data); }
    return raw_test_data;
}
