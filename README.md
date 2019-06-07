# zug-tap

TAP (Test Anything Protocol) for D

## VERSION

pre-alpha

## STATUS

 - ok(true, "some message") works 
 - summaries work
 - subtests kind of work
 - skipping tests with message works
 - diag/notes work

## PLAN

The tests should be easy to write and easy to read, without boilerplate. The 
ideal experience would be to instantiate a test, then write code as if you're
using your library and add "t.ok" or "t.is" from place to place to check the 
results are what you expect.

 - is(true, true, "true is true") : see if two variables have the same values, if not print what was given and what was expected
 - same(some_object, some_object, "are the same") : see if two values are the same thing (such as pointers to the same address), if not give more details 
 - isa(...): check type or parent of type
 - is_deeply(...) : check if two datastructures have the same values
 - bail_out()
 - todo()
 - ... aiming at a similar API like Test::More has
 - test with established TAP consumers
 

## WHY 

I have no strong opinion about what is the right way to add tests and
I have used "unittest" blocks and have been mostly satisfied with the 
result. 

What I felt was missing was a visual feedback, the ability to continue
to run the tests even if one of them fails and summaries about how many
tests failed and how many passed, and the TAP way of writing automatic
tests provides that without too much boilerplate.

## HOWTO

look in the "examples" folder or in the unittest blocks in the code

## CREDITS

Perl's Test::Simple https://perldoc.perl.org/Test/Simple.html

Perl's Test::More https://perldoc.perl.org/Test/More.html

https://dlang.org/blog/2017/10/20/unit-testing-in-action/

