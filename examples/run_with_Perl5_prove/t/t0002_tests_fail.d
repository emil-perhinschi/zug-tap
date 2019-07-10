void main() 
{
    import zug.tap;
    import testlib;
    import std.stdio;

    auto tap = Tap("second unittest block");
    tap.verbose(true);
    tap.plan(5);
    tap.ok(test_false(), "should fail 1");
    tap.ok(test_false(), "should fail 2");
    tap.ok(test_false(), "should fail 3");
    tap.ok(test_false(), "should fail 4");
    tap.ok(test_false(), "should fail 5");
    tap.done_testing();
}
