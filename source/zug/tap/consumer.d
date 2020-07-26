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
                debug writeln("HIDDEN DIR found ", entry.name);
                continue;
            }
            debug writeln("DIR found ", entry.name);
            files ~= read_dir(entry.name);
        } else {
            if (!entry.name.match(r"\.d$")) {
                debug writeln("NOT A .D FILE", entry.name);
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

    debug writeln("file paths ", file_paths);

    return ["abc"];
}

struct TestResults {
    int passed = 0; // passed tests
    int failed = 0; // failed tests
    int planned = 0; // planned tests;
    bool done_testing = false; // did we see "done testing" printed to STDOUT
}

TestResults run_test(string test, bool verbose = false, bool do_debug = false) {
    import std.stdio : writeln, writefln;
    import std.process : pipeProcess, Redirect, wait;
    import std.regex : ctRegex, match;
    import std.uni : toLower;

    TestResults raw_test_data;

    debug writeln("running ", test);

    auto processPipe = pipeProcess(["/usr/bin/dub", "--single", test],
            Redirect.stdout | Redirect.stderr);
    scope (exit)
        wait(processPipe.pid);

    debug writeln("ran ", test, " looking at output");
    auto plan = ctRegex!(`^\s*\d+\.\.\d+`, "i");
    auto ok = ctRegex!(`^\s*ok`);
    auto not_ok = ctRegex!(`^\s*not ok`);
    auto diagnostic = ctRegex!(`^\s*#diagnostic:`);
    auto note = ctRegex!(`^\s*#note:`);
    auto comment = ctRegex!(`^\s*#`);

    foreach (line; processPipe.stdout.byLine) {
        if (line.match(plan)) {
            debug writeln("PLAN: ", line);
        } else if (line.match(ok)) {
            debug writeln("OK: ", line);
        } else if (line.match(not_ok)) {
            debug writeln("NOT OK: ", line);
        } else if (line.match(diagnostic)) {
            debug writeln("DIAGNOSTIC: ", line);
        } else if (line.match(note)) {
            debug writeln("NOTE: ", line);
        } else if (line.match(comment)) {
            debug writeln("COMMENT: ", line);
        } else {
            debug writeln("DON'T KNOW: ", line);
        }
    }
    return raw_test_data;
}
