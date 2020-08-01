import std.algorithm : sort;
import zug.tap.consumer;


void main(string[] args) {
    import std.stdio : writeln;
    import std.getopt;
    import zug.tap.consumer : TestResults;
    import std.conv: to;

    string tests_folder = "t";
    bool verbose = false;
    bool do_debug = false;
    bool help = false;
    TestResults[string] raw_test_data;

    auto options = getopt(
            args,
            "t|test_folder", &tests_folder,
            "verbose", &verbose,
            "debug", &do_debug,
            "help", &help);

    auto files = read_dir(tests_folder, verbose, do_debug);

    writeln([
        " verbose ", verbose.to!string,
        " debug ", do_debug.to!string,
        " help ", help.to!string
    ]);
// TODO: help
    debug writeln("files ", files.sort());

    auto test_files = read_test_files(tests_folder);

    debug writeln("found tests ", test_files);

    foreach (string test; files) {
        raw_test_data[test] = run_tes(test, verbose, do_debug)
    }

    writeln(raw_test_data);
    int number_of_test_files;
    int number_of_tests;
    bool success = true;
    foreach (string test_file; raw_test_data.keys) {
        auto test_data = raw_test_data[test_file];

        writeln("Test: ", test_file);
        if (verbose) {
            writeln("\tpassed:\t", test_data.passed);
            writeln("\tfailed:\t", test_data.failed);
            writeln("");
        }

        number_of_tests += test_data.passed;
        number_of_test  += test_data.failed;

        if (test_data.failed > 0) {
            success = false;
        }
        if (test_data.planned > test_data.passed) {
            success = false;
        }
        // writeln("\tsuccess: ", raw_test_data[test_file].success);
    }
    
    writeln("Files=", number_of_test_files, ", Tests:", number_of_tests, " , TODO time it took" );
    if (success == true) {
        writeln("Result: PASS");
    } else {
        writeln("Result: FAIL");
    }

}
