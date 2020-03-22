module zug.tap.consumer;


string[] read_dir(string source_dir, bool verbose = false, bool do_debug = false)
{
    import std.stdio: writeln;
    import std.file: DirEntry, dirEntries, SpanMode;

    import std.array: array;
    import std.path: baseName;
    import std.string: indexOf;
    import std.regex: match;

    string[] files;

    auto entries =  dirEntries(source_dir, "*", SpanMode.shallow);
    foreach (DirEntry entry; entries) 
    {
        if (entry.isDir)
        {
            if (entry.name.baseName.indexOf('.') == 0) {
                writeln("HIDDEN DIR found ", entry.name);
                continue;
            } 
            writeln("DIR found ", entry.name);
            files ~= read_dir(entry.name);
        }
        else 
        {
            if (! entry.name.match(r"\.d$") ) {
                writeln("NOT A .D FILE", entry.name);
                continue;
            }

            files ~= entry.name;
        }
    }

    return files;
}

string[] read_test_files(string test_dir, bool verbose = false, bool do_debug = false)
{
    import std.stdio: writeln;
    import std.file: dirEntries, SpanMode;
    import std.algorithm: sort;
    import std.array: array;
    // TODO: check dir exits, etc.

    auto files = dirEntries(test_dir, "*.d", SpanMode.shallow);
    auto file_paths = array(files);

    writeln( "file paths ", file_paths );

    return ["abc"];
}

void run_test(string test, bool verbose = false, bool do_debug = false)
{
    import std.stdio : writeln, writefln;
    import std.process : pipeProcess, Redirect, wait;
    import std.regex : ctRegex, match;

    writeln("running ", test);

    auto processPipe = pipeProcess(["/usr/bin/dub", "--single", test],
            Redirect.stdout | Redirect.stderr);
    scope (exit)
        wait(processPipe.pid);
    writeln("ran ", test, " looking at output");
    auto plan = ctRegex!(`^\s*\d+\.\.\d+`);
    auto ok = ctRegex!(`^\s*ok`);
    auto not_ok = ctRegex!(`^\s*not ok`);
    auto diagnostic = ctRegex!(`^\s*#DIAGNOSTIC:`);
    auto note = ctRegex!(`^\s*#NOTE:`);
    auto comment = ctRegex!(`^\s*#`);

    foreach (line; processPipe.stdout.byLine)
    {

        if (line.match(plan))
        {
            writeln("PLAN: ", line);
        }
        else if (line.match(ok))
        {
            writeln("OK: ", line);
        }
        else if (line.match(not_ok))
        {
            writeln("NOT OK: ", line);
        }
        else if (line.match(diagnostic))
        {
            writeln("DIAGNOSTIC: ", line);
        }
        else if (line.match(note))
        {
            writeln("NOTE: ", line);
        }
        else if (line.match(comment))
        {
            writeln("COMMENT: ", line);
        }
        else
        {
            writeln("DON'T KNOW: ", line);
        }

    }


}
