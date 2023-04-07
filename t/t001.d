#!/usr/bin/env dub
/+ dub.json: { "name": "t001", "dependencies": { "zug-tap": { "path": "../" } } } +/


void main() {
    import zug.tap;

    auto tap = Tap("tap test 1");
    tap.verbose(true);
    tap.plan(7);
    tap.note("Some tests are expected to fail. You should see this message when verbose was set to true in both test and consumer (that is 'proved').");
    tap.diag("this is a diagnostic message");
    tap.verbose(false);
    tap.note("This is a note that should not be seen because verbose was set to false in test.");
    tap.verbose(true);
    tap.ok(true, "is true indeed");
    tap.ok(true, "is true indeed");
    tap.ok(false, "failed indeed");
    tap.ok(true, "is true indeed");
    tap.ok(true, "is true indeed");
    tap.ok(false, "failed indeed");
    tap.ok(true, "is true indeed" );
    tap.done_testing();
}
