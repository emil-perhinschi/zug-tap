void main()
{
    import std.stdio;
    import std.file : dirEntries, SpanMode;
    import std.process;

    foreach (string test; dirEntries("./t", "*.d", SpanMode.shallow))
    {
        // auto pid = spawnProcess([ "/usr/bin/dub", "--single", test ]);
        // wait(pid);

        run_test(test);
    }

}

void run_test(string test)
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
