void main() {
    import std.stdio;
    import std.file: dirEntries, SpanMode;
    import std.process;

    foreach (string test; dirEntries("./t", SpanMode.shallow) )
    {
        auto pid = spawnProcess([ "/usr/bin/dub", "--single", test ]);
        wait(pid);
    }
    
}