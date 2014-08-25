---
title: Using systemd template files
description: >
    I ran into some problems setting up systemd template files. Here's how I
    solved them.
layout: post
---
Arch Linux ships with [systemd][] as the system management daemon. It's very
cool, but I struggled for an embarassing amount of time with getting it to start
[envoy][] (an ssh-agent management tool). The problem I encountered was mostly
due to my naïve assumption about the autocompleted service files.

Specifically, bash autocompleted

```bash
systemctl enable envoy
```

To:

```bash
systemctl enable envoy@service.service
```

I didn't really know what the "@" meant, so I assumed it was correct and ran
with it. On my next restart it failed, and after some research I finally figured
out why. The "@" in systemd filenames signifies that the file is a "template"
file. There's a really good explanation on [stackoverflow][]. Here's the
relevant part:

>The @ symbol is for special services where multiple instances can be run.
>
>For instance, `getty@.service` is the service that provides text login
>terminals. When you press `Ctrl`+`Alt`+`F2`, getty@tty2.service is started,
>creating virtual terminal #2.

Basically, the part after the "@" and before the extension (".service" in this
case) is a variable that's used inside the service file. I disabled
"envoy@service.service", enabled "envoy@ssh-agent.service" and reloaded systemd.
Everything's working now and I understand systemd better.

As a sidenote, I found the following commands to be really helpful in debugging
problems related to systemd:

```bash
# Show a service file's details, including file location
systemctl show [service name]
# Show failed units
systemctl --failed
# Show all logs this boot (-b) related to that service file
journalctl -b | grep [service name]
```

[systemd]: http://en.wikipedia.org/wiki/Systemd
[envoy]: https://github.com/vodik/envoy
[stackoverflow]: http://superuser.com/questions/393423/the-symbol-and-systemctl-and-vsftpd
