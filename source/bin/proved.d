import zug.tap.consumer;


void main(string[] args) {
    import std.stdio : writeln, write, stderr;
    import std.array: array;
    import std.algorithm : sort;
    import std.algorithm.iteration: reduce, map;
    import std.format: format;
    import std.getopt;
    import std.conv: to;
    import std.datetime.stopwatch;
    import std.algorithm.comparison : max;
    import std.file: isDir, exists;

    string tests_folder = "t";
    bool verbose = false;
    bool do_debug = false;
    bool help = false;
    TestResults[string] raw_test_data;

    auto options = getopt(
            args,
            "t|test_folder", &tests_folder,
            "v|verbose", &verbose,
            "d|debug", &do_debug,
            "h|help", &help);

    if (help) {
        import core.stdc.stdlib: exit;
        writeln(`
Usage: proved -t /home/user/folder_with_zug-tap_test_files/

Arguments: 
  -t, --test_folder: where are the test files that I need to execute
  -v, --verbose: tests print more information; can be overriden from within the test file
  -d, --debug: debug statements are printed
  -h, --help: print this
        `);
        exit(0);
    }

    if (do_debug) { verbose = true; }
    if (!tests_folder.exists || !tests_folder.isDir) {
        import core.stdc.stdlib: exit;
        stderr.writeln(format!"Error: tests folder '%s' not found"(tests_folder));
        exit(1);
    }
    auto files = read_dir(tests_folder, verbose, do_debug).sort();

    if (do_debug) { writeln("files ", files.sort()); }
/*
// one way to do benchmarks
    void do_benchmark() {
        foreach (string test; files) {
            raw_test_data[test] = run_test(test, verbose, do_debug);
        }
    }

    auto benchmark_result = benchmark!(do_benchmark)(1);
    writeln("====================================================== ", benchmark_result);

*/
    auto sw = StopWatch(AutoStart.no);
    sw.start();
    foreach (string test; files) {
        raw_test_data[test] = run_test(test, verbose, do_debug);
    }
    sw.stop();

    if (do_debug) { writeln(raw_test_data); }

    int number_of_test_files;
    int number_of_tests;
    bool success = true;
    writeln("\nTest Summary Report");
    writeln("-------------------");
    foreach (string test_file; raw_test_data.keys.sort) {
        auto test_data = raw_test_data[test_file];
        string test_info = format!"%-30s  passed: %d, failed: %d"(test_file, test_data.passed, test_data.failed);
        writeln(test_info);
        number_of_tests += test_data.passed;
        number_of_tests += test_data.failed;
        number_of_test_files++;
        if (test_data.failed > 0) {
            success = false;
        }
        if (test_data.planned > test_data.passed) {
            success = false;
        }
    }
    writeln("Files=", number_of_test_files, ", Tests:", number_of_tests, " , ", sw.peek.total!"msecs", " msecs" );
    if (success == true) {
        writeln("Result: PASS");
    } else {
        writeln("Result: FAIL");
    }

}
