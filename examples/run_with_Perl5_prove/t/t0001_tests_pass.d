#!/usr/bin/env dub
/+dub.json: { "dependencies": { "zug-tap": "*", "testlib": { "path": "../" }  } } +/

import zug.tap;
import testlib;

void main() 
{
    auto tap = Tap("second unittest block");
    tap.verbose(true);
    tap.plan(5);
    tap.ok(test_true(), "should pass 1");
    tap.ok(test_true(), "should pass 2");
    tap.ok(test_true(), "should pass 3");
    tap.ok(test_true(), "should pass 4");
    tap.ok(test_true(), "should pass 5");
    tap.done_testing();
}
