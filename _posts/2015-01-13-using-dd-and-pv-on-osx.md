---
title: Using dd and pv on OS X
description: >
    I find myself burning ISOs to flash drives fairly often. This is the best
    and quickest way I've found of doing it.
layout: post
---

I find myself burning ISOs to flash drives fairly often. This is the best and
quickest way I've found of doing it (on OS X - your experience with other
systems and non-BSD tools may differ):

```bash
$FILE=my_cool_new_distro.iso
$RDISK=/dev/rdisk1 # diskutil list

dd if=$FILE \
    | pv -tpreb -s $(du -k $FILE | awk '{print $1}')k \
    | sudo dd of=$RDISK bs=1m
```

Notes
-----
- $RDISK should have the `r` in front (i.e. `/dev/rdisk1` not `/dev/disk1`),
  that tells the kernel not to buffer it. It will display as `/dev/disk1` in
  `diskutil list`, but you should put the `r` in front. This makes it faster.

- `bs=1m` tells dd to use a blocksize of 1m. This makes it faster.

- `$(du -k $FILE | awk '{print $1}')k` is a hack to make sure that dd
  understands the units being shown in du's answer. We pass the -k flag to du,
  which asks it to display the size of the file in kilobyte blocks. The snippet
  then has a trailing 'k', which makes it clear that the result is in
  kilobytes. This just gives you a progress bar.
