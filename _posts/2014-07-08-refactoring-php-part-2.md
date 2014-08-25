---
title: Refactoring a PHP application, part 2
description: >
    An introduction to the idea of refactoring a PHP application
layout: post
---

>This is the second post in the series. The first post is [available
>here][first_post].

[first_post]: http://ciarand.me/posts/refactoring-php-part-1/

In the last post we talked about exactly what we'd be working with, and more
importantly what we want to end up with. In this post we'll be talking about
getting a single entry point enabled.

First, let's move our project directory into a subfolder. We're going to start
using a "public" directory, so there will be some project files above that.
Something like this might work for you, but **you should double check that only
files that should be publically accessible are in the public directory.** For
example, your `.git` directory **should not** be in your `public/` directory.

```bash
# move all the front-end assets into a public dir
find . -type f \( \
        -name "*.css" -o  \
        -name "*.html" -o \
        -name "*.js" -o \
        -name "robots.txt" -o \
        -name "humans.txt" -o \
        -name "favicon.ico" -o \
        -name ".htaccess" \) |
    while read file
    do
        mkdir -p "public/$(dirname $file)"
        mv "$file" "public/$file"
    done

# move all the PHP files into a "handlers" directory
find . -name '*.php' | while read file; do
    mkdir -p "handlers/$(dirname $file)"
    mv "$file" "handlers/$file"
done
```

We'll be creating our entry script (`index.php`) inside the public directory.
This will be where all our dynamic app requests get processed, so we'll put our
dispatch and routing logic here. But first we need a way of sending the requests
to this file, which is where server config rules come into play.

If you're using Nginx, you can use something like this:

```bash

# change the try_files directive to
try_files $uri $uri/ /index.php?$args
```

The preferred method for Apache users is now the `FallbackResource` directive.
If you're using Apache v2.2.16 or higher, you can put this in your `.htaccess`
or `httpd.conf` file (make sure the `.htaccess` file is in your `/public`
directory):

```bash
FallbackResource /index.php
```

Older Apache users are stuck with RewriteRules (placed in the same file):

```bash
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule ^ index.php [QSA,L]
```

For those few Lighttpd users, I've been told this will get you up and running:

```bash
url.rewrite-if-not-file = ("(.*)" => "/index.php/$0")
```

To test this works, let's check the superglobals in our entry script
(`public/index.php`):

```php
<?php echo $_SERVER["SCRIPT_NAME"];
```

Visiting the root (`/`) entry point should output something like this:

```bash
/
```

Visiting an arbitrary endpoint, say `/lorem/ipsum/blah/blah`, should output
something like this:

```bash
/lorem/ipsum/blah/blah
```

Cool! We've got an entry script that can effectively handle all of our future
requests.

Now we need to setup some code inside the `index.php` to forward requests to the
same files as before. For the sake of this post series I've created a quick and
dirty router. You can find it [here][router]. Assuming you have [Composer][]
installed globally, setting it up will look something like this:

[router]: https://github.com/ciarand/quick-n-dirty-php-router
[Composer]: http://getcomposer.org/

```bash
composer require 'ciarand/quick-n-dirty-php-router' 'dev-master'
```

All you need in your `public/index.php` file is this:

```php
<?php // index.php

require "vendor/autoload.php";

use Ciarand\Router;

// where you keep your scripts (outside of the public web dir)
$handler_dir = __DIR__ "/../handler";

// the script you'd like to handle 404s with
// (this isn't strictly necessary, but it's a nice touch)
$missing_script = $handler_dir . "/404.php";

$request = $handler_dir . "/" . Router::scriptForEnv($_SERVER);

return require (file_exists($request))
    ? $request
    : $missing_script;
```

Okay, so now we can run some tests. Try opening some random URLs that worked
before and make sure they still work. This is just a quick sanity check as the
router is unit tested, but everyone's configuration is different and you may
encounter some project-specific bugs. Make sure to test:

- subdirectories (i.e. `/subdir/` and `/subdir` should show the same thing as
  `/subdir/index.php`)

- static assets (css, js, image files)

- 404s

Great! We've got a single entry point and we haven't broken anything! We can
safely start adding features via required files to the `index.php` and make sure
we don't repeat any effort. More importantly, we've made a huge step in the
direction of moving toward a more automated, test-friendly system.

In the next post we'll go over how to add some functional tests so we can be
sure our future efforts don't break anything.
