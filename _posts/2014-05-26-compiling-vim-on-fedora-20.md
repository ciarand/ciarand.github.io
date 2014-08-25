---
title: Compiling Vim on Fedora 20
description: >
    I ended up needing to compile Vim from scratch on F20, and it was more of
    an ordeal than I'd hoped. Here's how I did it.
slug: compiling-vim-on-fedora-20
layout: post
date: 2014-05-26
---

Vim is my editor of choice. I was recently playing around with a Fedora
installation and realized that even the `vim-enhanced` package available via
`yum` was not as feature-complete as the one on my MacBook (compiled with
homebrew's help).

I decided I'd need to compile it from scratch. Here's how I did that:

>Note: I already had multiple versions of Ruby compiled from a previous Ansible
>script I ran. You may have to get Ruby before this, either through `yum` or by
>compiling it yourself.

```bash
# first update yum
sudo yum update -y

# remove any old versions of vim
sudo yum remove vim

# install extra deps
sudo yum install -y lua lua-devel luajit luajit-devel \
    ctags mercurial python python-devel \
    python3 python3-devel tcl-devel \
    perl perl-devel perl-ExtUtils-ParseXS \
    perl-ExtUtils-Xspp perl-ExtUtils-CBuilder

# symlink xsubpp (perl) from /usr/bin to the perl dir
sudo ln -s /usr/bin/xsubpp /usr/share/perl5/ExtUtils/xsubpp

# use ~/src as our compile dir
mkdir -p ~/src && cd ~/src

# clone the vim repo
hg clone https://vim.googlecode.com/hg vim

# configure it
cd vim
./configure --enable-fail-if-missing \
    --enable-luainterp --with-luajit \
    --enable-perlinterp \
    --enable-pythoninterp \
    --enable-python3interp \
    --enable-rubyinterp \
    --enable-tclinterp \
    --enable-multibyte \
    --enable-fontset

# install it in /usr/share/vim/vim74
VIMRUNTIMEDIR=/usr/share/vim/vim74 sudo make install
```

And there you have it! That should install the supporting files to
`/usr/share/vim/vim74` and the new Vim binary to `/usr/local/bin/vim`.

>The full Ansible script I've used here is available in my [dotfiles][].

[dotfiles]: https://github.com/ciarand/phoenix/blob/master/roles/editor/tasks/RedHat_extras.yml
