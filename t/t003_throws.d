#!/usr/bin/env dub
/+dub.json: { "name": "t003_throws", "dependencies": { "zug-tap": { "path" : "../"}  } } +/

void main() {
    import zug.tap;

    class MyException: Exception { 
        this(string msg) { 
            super(msg); 
        }
    }
    
    class SecondException: Exception { 
        this(string msg) { 
            super(msg); 
        }
    }


    class ThirdException: Exception { 
        this(string msg) { 
            super(msg); 
        }
    }
    auto tap = Tap("testing exceptions");

    tap.verbose(true);
    auto del = delegate void() { throw new MyException("an exception was thrown"); };
    tap.ok( it_throws!MyException(del), "it throws MyException, as expected, as expected");
    tap.ok(!it_throws!SecondException(del), "it does not throw SecondException, as expected");
    tap.ok( it_throws!Exception(del), "did it throw an Exception ?"); 
    auto del_no_throw = delegate void() { };
    tap.ok(!it_throws!MyException(del_no_throw), "it does not throw MyException as expected ");
    tap.done_testing();
    tap.report();
}


