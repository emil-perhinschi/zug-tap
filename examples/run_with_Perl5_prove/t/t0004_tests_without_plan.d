#!/usr/bin/env dub
/+dub.json: { "dependencies": { "zug-tap": "*", "testlib": { "path": "../" }  } } +/

import zug.tap;
import testlib;

void main()
{
    auto tap = Tap("tests without plan should work too");
    tap.verbose(true);
    tap.ok(true);
    tap.ok(!false);

    tap.done_testing();
}
