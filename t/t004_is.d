#!/usr/bin/env dub
/+ dub.json: { "name":"t004_it_id",  "dependencies": { "zug-tap": { "path": "../" } } } +/


void main() {
    import zug.tap;

    auto tap = Tap("tap test 1");
    tap.verbose(true);
    tap.note("Some tests are expected to fail. You should see this message when verbose was set to true in both test and consumer (that is 'proved').");
    # TODO tap.it_is(true, false, "should fail" );
    tap.done_testing();
}

