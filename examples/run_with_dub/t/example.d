
void main() 
{
    import std.process;
    import zug.tap;
    import dubtest;

    auto tap = Tap();
    assert(tap.verbose == true);
    tap.plan(2);    
    tap.ok(1, "one is true");
    tap.ok(!dubtest.bla(), "bla returns false");
    tap.done_testing();
    tap.report();
}

