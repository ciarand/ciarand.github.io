---
title: Installing Neovim
description: >
    I'm a supporter of the Neovim project. I just recently made the plunge and
    switched full-time. Here's how I got my environment setup correctly:
layout: post
---

Update: This isn't necessarily up to date any more. Check the [Neovim
wiki](https://github.com/neovim/neovim/wiki/Installing-Neovim) for the most
up-to-date instructions.

[Neovim][nvim] has been moving along quite steadily over the last six months,
and it's finally starting to hit a level of stability where I feel comfortable
using it full-time. I did have to jump through a few minor hoops to get it
working, however:

[nvim]: http://neovim.org/

Homebrew
--------
I use [Homebrew][brew] to handle my dependencies, as you'd expect, so
[this][installation] was the first thing I tried:

```bash
brew tap neovim/neovim
brew install neovim --HEAD
```

[brew]: http://brew.sh/
[installation]: https://github.com/neovim/neovim/wiki/Installing

Unfortunately it failed with an unknown error and ate my error logs before
I could view them. On to the next method!

Installing by hand
------------------

The instructions claim that this command will install the required Luarocks
modules:

```bash
make CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX:PATH=$HOME/neovim" install
```

But I ended up having to install them by hand:

```bash
brew install luarocks
luarocks install lpeg
luarocks install lua-messagepack
luarocks install luabitop
# for tests
luarocks install busted
```

Once that was done I could correctly run the above command:

```bash
make CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX:PATH=$HOME/neovim" install
```

Making plugins work
-------------------
I use quite a few plugins to make some boring tasks easier, and Vundle to
manage them. Luckily moving them over was a very simple matter:

```bash
cp ~/.vimrc ~/.nvimrc
pip install neovim
```

Tmux navigation
---------------
This is what my old .tmux.conf file looked like:

```
bind -n C-h run "(tmux display-message -p '#{pane_current_command}' | grep -iqE '(^|\/)vim(diff)?$' && tmux send-keys C-h) || tmux select-pane -L"
bind -n C-j run "(tmux display-message -p '#{pane_current_command}' | grep -iqE '(^|\/)vim(diff)?$' && tmux send-keys C-j) || tmux select-pane -D"
bind -n C-k run "(tmux display-message -p '#{pane_current_command}' | grep -iqE '(^|\/)vim(diff)?$' && tmux send-keys C-k) || tmux select-pane -U"
bind -n C-l run "(tmux display-message -p '#{pane_current_command}' | grep -iqE '(^|\/)vim(diff)?$' && tmux send-keys C-l) || tmux select-pane -R"
```

This is what my new .tmux.conf file looks like:

```
bind -n C-h run "(tmux display-message -p '#{pane_current_command}' | grep -iqE '(^|\/)(n)?vim(diff)?$' && tmux send-keys C-h) || tmux select-pane -L"
bind -n C-j run "(tmux display-message -p '#{pane_current_command}' | grep -iqE '(^|\/)(n)?vim(diff)?$' && tmux send-keys C-j) || tmux select-pane -D"
bind -n C-k run "(tmux display-message -p '#{pane_current_command}' | grep -iqE '(^|\/)(n)?vim(diff)?$' && tmux send-keys C-k) || tmux select-pane -U"
bind -n C-l run "(tmux display-message -p '#{pane_current_command}' | grep -iqE '(^|\/)(n)?vim(diff)?$' && tmux send-keys C-l) || tmux select-pane -R"
```

All I've done is add the `(n)?` prefix to the grep pattern (and reloaded the
conf file via `tmux source-file ~/.tmux.conf`).

Conclusion
----------
Everything works, and it seems snappier. I'm excited, and I'll post some more
details when / if I encounter any more problems.
