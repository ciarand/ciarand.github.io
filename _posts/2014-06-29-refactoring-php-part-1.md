---
title: Refactoring a PHP application, part 1
description: >
    An introduction to the idea of refactoring a PHP application
layout: post
---

>This is the first post in the series. The second post is [available
>here][second_post].

[second_post]: {% post_url 2014-07-08-refactoring-php-part-2 %}

There's been a refreshing wave of change in the way we build web applications in
PHP over the last few years. The advent of [Composer][] and the wave of modular,
reusable components it's brought us have dramatically improved the architecture
of new applications. Unfortunately for the developers forced to maintain them,
not all applications are taking advantage of these new and powerful tools. In
this series I'll be discussing the process of upgrading and refactoring
a typical "old school" site built with PHP into a solid, well tested
application.

[composer]: http://getcomposer.org

Let's first discuss what we're working with. I'm assuming a multipage site with
multiple entry points. The ones I've seen and worked with tend to have lines
like `include "inc/header.php"`. There's frequently code that's been copied and
pasted in multiple places, and these snippets often have minute and unmarked
differences. There's rarely any form of testing or build process, and the
business login is often intertwined with the display login.

>Note: this process is not specific to PHP or even to sites structured like
>this, but for simplicity's sake (and because of how often I see sites like this
>in the wild) this is the base we'll be working from.

Now that we know what we're working with, let's establish what we'd like to end
up with:

- A single entry point (`index.php`) in the public web directory

- A full set of tests, both unit and functional, that insure the site is
  functioning correctly at all times

- A modern deployment process, using Docker, Nginx, and PHP-FPM

- A way of interacting with the code from the command line effectively. Any HTTP
  request should be able to be perfectly simulated from any SAPI (cli, phpdbg,
  etc.)

Let's begin.
