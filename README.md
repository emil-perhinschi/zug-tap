# zug-tap

TAP (Test Anything Protocol) for D

## VERSION

alpha

I tested only on Linux

I don't expect it to work on other operating systems: for example I rely on "/usr/bin/env" being available 

## SYNOPSIS

zug-tap can be used either in an `unitest` block or using separate test files.

### using builtin "proved"
build "proved" with
```
dub build :proved
```
then copy `proved` somewhere in your path and run it
```
proved
```

Options for `proved`
 - v|verbose: more details
 - d|debug: a lot more details
 - t|test_folder: under which folder are the test files kept

For example:
`$ proved -v -t ./t`

### In "unittest" block, using an external consumer, for example tappy
```
unittest {
    import std.file;
    import std.process;
    import zug.tap;

    string path_to_tappy = "/usr/bin/tappy";
    // start a new test
    auto tap = Tap("test with pipe to tappy");
    tap.verbose(false); // default is true

    if ( path_to_tappy.exists && path_to_tappy.isFile ) {
        auto pipe = pipeProcess(path_to_tappy, Redirect.stdin);
        tap.set_consumer(pipe);
    }
    else {
        tap.verbose(true);
        tap.skip("tappy not found, skipping the consumer pipe tests");
    }

    tap.plan(6);
    tap.ok(true, "should pass 1");
    tap.ok(true, "should pass 2");
    tap.ok(true, "should pass 3");
    tap.ok(true, "should pass 4");
    tap.ok(true, "should pass 5");
    tap.ok(false, "should fail 6");
    tap.done_testing();

    // not calling report(), let tappy do the reporting
    // tap.verbose(true);
    // tap.report();
}
```

### In a "unittest block", without a consumer
```
{
    auto tap = Tap("second unittest block");
    tap.verbose(true);
    tap.ok(true, "should pass");
    tap.ok(true, "should pass");
    tap.skip("skipping two out of six tests");
    tap.ok(true, "should pass");
    tap.ok(true, "should pass");
    tap.resume("skipped two tests out of six, resuming");
    tap.ok(true, "should pass");
    tap.ok(true, "should pass");
    tap.ok(false, "should fail 6");
    tap.done_testing();

    writeln(tap.results().length); // 5
    writeln(tap.tests_skipped); // 2
    writeln(tap.tests_failed); // 1
    writeln(tap.tests_passed); // 4
    tap.report(); // print a summary, not parseable by a tap reporter
}
```

### Using "prove" from CPAN

see under examples/run_with_Perl5_prove/

## WHAT WORKS SO FAR
 - ok( some == other, "some message")
 - report(): prints a summary to STDOUT
 - skip("message"): skipping tests with message
 - resume("message"): stop skipping tests
 - diag(): messages which don't interfere with parsers but are shown even when **verbose** is false
 - note(): messages which don't interfere with parsers and are shown only when **verbose** is true
 - piping to an external consumer (tested with tappy)
 - running tests with prove from Perl 5 ( https://perldoc.perl.org/prove.html ): see ./examples/run_with_Perl5_prove
 - running tests with the builtin `proved` consumer
 - plan, either specified at the beginning, in which case the tests will count as failed if not enough or too many tests were ran, or computed at the end when running done_testing(), in which case there should be no failed tests

## TODO, maybe
  - is(true, true, "true is true") : see if two variables have the same values, if not print what was given and what was expected
 - same(some_object, some_object, "are the same") : see if two values are the same thing (such as pointers to the same address), if not give more details
 - isa(...): check type or parent of type
 - is_deeply(...) : check if two datastructures have the same values
 - bail_out()
 - todo()
 - explain() : dump data structure
 - ... aiming at a similar API like Test::More has
 - write .tap files
 - run the test files in parallel
TODO code:
 - get test final report as a struct
 - get test final report as json/csv


## WHY

I have no strong opinion about what is the right way to add tests and
I have used "unittest" blocks and have been mostly satisfied with the
result.

What I felt was missing was a visual feedback, the ability to continue
to run the tests even if one of them fails and summaries about how many
tests failed and how many passed, and the TAP way of writing automatic
tests provides that without too much boilerplate.

## PLAN

Tests should save you time despite the extra typing. Still, a lot of the testing
frameworks I have seen used require a lot of boilerplate, and even if they don't
programmers write a lot of boilerplate anyway so testing gets hard and automatic
tests end up either taking a lot of time or get abandoned because "it is too
expensive".

The tests should be easy to write and easy to read, without boilerplate. The
ideal experience would be to instantiate a test object, then write code as if
you're using your library and add "t.ok(...)" or "t.is(...)" from place to place
to check the results are what you expect.

## HOWTO

### How to write tests

look in the "examples" folder or in the unittest blocks in the code

### How to build the consumer

dub build :proved

## CREDITS

Perl's Test::Simple https://perldoc.perl.org/Test/Simple.html

Perl's Test::More https://perldoc.perl.org/Test/More.html

https://dlang.org/blog/2017/10/20/unit-testing-in-action/

## NOTES

some of the tests under t/ are expected to fail
