---
title: Writing CLI unit tests in Perl
description: >
    I recently had to write some unit tests for a small (C) cli script that I
    was writing for an assignment
layout: post
---

I was recently asked to write a small C script for reading some basic system
stats. Nothing particularly exciting, and certainly not worth including any
large unit testing frameworks for. Going without any tests at all (*going
commando*) just doesn't feel right though. Instead, I decided to use Perl and
its [Test::Simple][] module to write some quick tests.

[Test::Simple]: https://metacpan.org/pod/Test::Simple

Here's our program (stored in `script.c`, compiled to `script`):

```c
#include <stdio.h>

int main(int argc, const char* argv[]) {
    printf("argc: %d", argc);

    if (argc == 1) {
        printf("you called this script with no arguments\n");
    } else if (argc == 2) {
        printf("you called this script with 1 argument\n");
    } else {
        printf("you called this script with %d arguments\n", argc - 1);
    }

    return 0;
}
```

Easy enough, we can test this. Here's our test script:

```php
#!/usr/bin/env perl -w

use strict;
use warnings;

use Test::Simple tests => 4;

ok(`./script` =~ /no arguments$/, "no args");
ok(`./script foo` =~ /1 argument$/, "1 arg");
ok(`./script foo bar` =~ /2 arguments$/, "2 args");
ok(`./script foo bar baz` =~ /3 arguments$/, "3 args");
```

Super simple. Let's go over the parts of the script.

```php
#!/usr/bin/env perl -w
```

Perl's she-bang line. This just tells the kernel to run this script using the
user's Perl bin with the `-w` (warn) flag on. Normally Perl let's you get away
with a lot of nonsense, and the `-w` flag restricts the level of nonsense that's
acceptable.

>Note: this post originally stated that the she-bang line was for the shell.
>[It's actually for the kernel][correction-source]. The More You Know™

[correction-source]: https://alpha.app.net/cmd/post/32317081

```php
use Test::Simple tests => 4;
```
Use the `Test::Simple` pod. The most important part here is the `tests => 4`,
which is where we tell the script that we're planning to run 4 tests. That way
it knows that if a different number of tests are run something went wrong and
it'll tell us.

```php
ok(`./script` =~ /no arguments$/, "no args")
ok(`./script foo` =~ /1 argument$/, "1 arg")
ok(`./script foo bar` =~ /2 arguments$/, "2 args")
ok(`./script foo bar baz` =~ /3 arguments$/, "3 args")
```

Ah, the meat of the script. The `ok` subroutine just tallies up a passed test if
the first argument is true or a failed test if it evaluates to false. The second
(optional) argument is a test title.

The backticks (`` ` ``) around the `./script` execute the command and return
the stdout. The `=~` just returns true if the regex on the right matches
the string on the left.

Running the script gets us:

```tap
λ ./test.pl
1..4
ok 1 - no args
ok 2 - 1 arg
ok 3 - 2 args
ok 4 - 3 args
```

There, that's an easy (and lightweight) way of testing simple cli scripts.
