#!/usr/bin/env dub
/+dub.json: { "dependencies": { "zug-tap": "*" } } +/


void main() {
    import zug.tap;

    auto tap = Tap("tap test 1");
    tap.verbose(true);
    tap.plan(7);
    tap.ok(true);
    tap.ok(true);
    tap.ok(false);
    tap.ok(true);
    tap.ok(true);
    tap.ok(false);
    tap.ok(true);
    tap.done_testing();
}