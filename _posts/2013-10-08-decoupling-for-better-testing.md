---
title: Decoupling for Better Testing
description: >
    Unless you start out with the right mindset, an application's
    natural progression is toward chaos, inefficiency, and disorder.
slug: decoupling-for-better-testing
layout: post
date: 2013-10-08
---
Unless you start out with the right mindset, an application's natural
progression is toward chaos, inefficiency, and disorder.

Why is tight coupling bad?
--------------------------
Tight coupling hurts your app in the long term. Let's use an example (the code
is in PHP, but the principles are generic).

```php
<?php # models/User.php

class User extends MyBaseClass
{
    // Snip

    public function IsAllowedOnCurrentPage()
    {
        $pageUrl = $_SERVER['PHP_SELF'];
        // Or, if you're using a framework:
        $pageUrl = Yifonyaverl::app()->url->current();

        return in_array($page, $this->allowedPages);
    }

    // Snip
}
```

Do you see the problem? It's *prescriptive*. The User model now needs to know
what page the user is trying to access. A better method? Have the requesting
entity (probably a controller of some sort) tell the user model what page to
check against, like this:

```php
# models/ImprovedUser.php

class ImprovedUser extends MyBaseClass
{
    // Snip

    public function IsAllowedOnUrl($url)
    {
        return in_array($page, $this->allowedPages);
    }

    // Snip
}
```

That all sounds well and good in theory, but why should you, the pragmatic
programmer, care? Well, because you like writing testable code. How would you
test the first function? You'd probably have to adjust the `$_SERVER` global
variable before the test, something that might impact your other tests. Here's
an example test case:

```php
# tests/UserTest.php

class UserTest extends PHPUnit_Framework_TestCase
{
    // Snip

    public function TestGuestIsNotAllowedInAdminArea()
    {
        // A generic guest user
        $guest = $this->fixtures['guest'];

        // "mocking" the URL
        $_SERVER['PHP_SELF'] = 'admin.php';
        $this->assertFalse($guest->isAllowedOnCurrentPage());
    }

    // Snip
}
```

This is broken and wrong. Who knows what other components rely on `PHP_SELF`
being accurate? Is your framework using it? Hopefully not, but that's not a risk
you want to take.  Here's a better way:

```php
# tests/ImprovedUserTest.php

class ImprovedUserTest extends PHPUnit_Framework_TestCase
{
    // Snip

    public function TestGuesIsNotAllowedInAdminArea()
    {
        // A generic guest user
        $guest = $this->fixtures['guest'];

        // Instead of mocking, we can pass the URL in directly
        $this->assertFalse($guest->isAllowedOnUrl('admin.php'));
    }

    // Snip
}
```

It's actually one line shorter, and far more testable. You could use a data
provider to test an entire set of pages very easily, and know full-well that the
**only** thing you're testing is the model's method. You've *isolated* the
method and the logic, and can rest assured that, once you've written the tests,
this method will never fail you. That's a comforting feeling.

In my next post I'll go over a technique for decoupling more complex
relationships using a [publisher / subscriber][pubsub] pattern.

[pubsub]: http://en.wikipedia.org/wiki/Publish%E2%80%93subscribe_pattern
