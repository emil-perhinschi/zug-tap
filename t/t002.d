#! /usr/bin/env dub
/+dub.json: { "dependencies": { "zug-tap": { "path": "../" } } } +/


void main() {
    import zug.tap;

    auto tap = Tap("tap test 1");
    tap.note("This note should be seen only when the consumer has verbose set to true.");
    tap.ok(true);
    tap.ok(true);
    tap.ok(false);
    tap.ok(true);
    tap.ok(true);
    tap.ok(false);
    tap.ok(true);
    tap.done_testing();
}
