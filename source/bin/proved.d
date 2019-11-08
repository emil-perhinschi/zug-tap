import std.algorithm: sort;

void main(string[] args)
{
    import std.stdio: writeln;
    import std.getopt;


    string tests_folder = "t";
    bool verbose = false;
    bool do_debug = false;
    bool help = false;

    auto options = getopt(
        args,
        "test_folder", &tests_folder,
        "verbose", &verbose,
        "debug", &do_debug,
        "help", &help
    );

    auto files = read_dir(tests_folder, verbose, do_debug);

    writeln(files.sort());
    // auto test_files = read_test_files(tests_folder);
    // writeln(test_files);
    // foreach (string test; test_files)
    // {
    //     run_test(test);
    // }
}


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

auto read_test_files(string test_dir, bool verbose = false, bool do_debug = false)
{
    import std.stdio: writeln;
    import std.file: dirEntries, SpanMode;
    import std.algorithm: sort;
    import std.array: array;
    // TODO: check dir exits, etc.

    string[] files;

    auto entries = dirEntries(test_dir, "*", SpanMode.shallow);
    writeln(entries);
    
    return entries.array.sort;

    // auto files = dirEntries(test_dir, "*.d", SpanMode.shallow);
    // auto file_paths = array(files);
    // writeln( file_paths );
    // return ["abc"];
}

void run_test(string test, bool verbose = false, bool do_debug = false)
{
    import std.stdio : writeln, writefln;
    import std.process : pipeProcess, Redirect, wait;
    import std.regex : ctRegex, match;

    writeln("doing ", test);

    auto processPipe = pipeProcess(["/usr/bin/dub", "--single", test],
            Redirect.stdout | Redirect.stderr);
    scope (exit)
        wait(processPipe.pid);

    auto plan = ctRegex!(`^\s*\d+\.\.\d+`);
    auto ok = ctRegex!(`^\s*ok`);
    auto not_ok = ctRegex!(`^\s*not ok`);
    auto diagnostic = ctRegex!(`^\s*#DIAGNOSTIC:`);
    auto note = ctRegex!(`^\s*#NOTE:`);
    auto comment = ctRegex!(`^\s*#`);

/*
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
*/

}
