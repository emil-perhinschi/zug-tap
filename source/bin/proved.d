import std.algorithm: sort;
import zug.tap.consumer;

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
        "t|test_folder", &tests_folder,
        "verbose", &verbose,
        "debug", &do_debug,
        "help", &help
    );

    auto files = read_dir(tests_folder, verbose, do_debug);

    writeln( "files ", files.sort() );
    
    auto test_files = read_test_files(tests_folder);

    writeln("found tests ", test_files);

    foreach (string test; files)
    {
        run_test(test, true, true);
    }
}
