---
title: "Boring is good"
description: >
    Boring things tend to be more reliable, more focused, and less likely to
    cause problems, especially in our industry.
layout: post
---

I just switched my blog engine again. I was previously using [Hugo][hugo], which
is a static site engine written in Go. It's an interesting project and there's
a lot to like about it. It's fast, being written in Go means that precompiled
binaries are available for any modern system, and did I mention it was fast?

If I'm being honest with myself, however, I didn't pick it for either of those
reasons. *I picked it because it was interesting and new*. But those same
attributes have caused me to have to do a lot of extra work, including migrating
a theme, fixing some issues with the `404.html` logic, and hand-crafting an
individual-post layout system. None of that work was particularly challenging,
though the layout system wasn't exactly fun. But - at least apart from the
`404.html` issue which may help some other users - it was very much a waste of
time.

If all I needed was a blog, I could have just used Jekyll. But I didn't, because
both Jekyll and Ruby are boring. They're not fun or sexy or interesting, they're
just there. Chugging along, doing what they're supposed to, not really drawing
a lot of attention to themselves.

But you know what? That's ok. I don't have to fight Jekyll to get it to generate
my blog. I don't have to create a custom publish / deploy workflow to get it to
work correctly within GitHub pages. I don't have to come up with fancy new
solutions to boring, old, **solved** problems.

It's stable, it's proven, and it gets out of my way. I can focus on doing and
expect my tools to Just Work™ without much input from me. That's the reason
I use vim. That's the reason I use Mac OS X. And now, that's the reason I use
Jekyll. They're boring, and they leave me to focus on solving real problems
instead of [reorganizing index cards as productivity porn][productivity].

[productivity]: http://www.merlinmann.com/better/
[hugo]: http://hugo.spf13.com
