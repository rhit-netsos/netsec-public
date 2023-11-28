---
layout: page
title: tmux setup
last_modified_date: Friday Nov 24 22:47:40 2023
current_term: Winter 2023-24
parent: Guides
nav_order: 30
description: >-
  General tmux setup and config file.
---

## Table of contents
{:.no_toc}

1. TOC
{:toc}

---

# Introduction

Since you will be working on multiple machines, you will need a really good
_terminal multiplexer_. I highly recommend
[tmux](https://github.com/tmux/tmux/wiki). `tmux` is already installed on the
class server (`netsec-01.csse.rose-hulman.edu`), but if you'd like to install
it locally, then any package manager would do (`apt`, `snap`, `brew`, etc.).

# Getting started

`tmux` is a terminal multiplexer that allows to arrange multiple windows and
panes within one terminal window. This will prove very useful when debugging
across several virtual machines in the labs for this class.

## Some definitions

Below are some definitions ported and modified from the [`tmux` official
guide](https://github.com/tmux/tmux/wiki/Getting-Started).

Pane
: Contains a single terminal window and running program, appear in one window.

Window
: Groups one or more panes together, linked to one or more sessions.

Session
: Groups one or more windows together.

Normally, you start by creating a _session_, which automatically creates a
_window_ with a single _pane_. Then you can start adding _panes_ to the same
window, adding _windows_ to the same session, or creating new _sessions_
altogether.

## The prefix key

Once in a `tmux` session, all what you type is sent directly to the terminal
running in the active pane. However, the magic of `tmux` comes from controlling
the multiplexer itself.

To indicate that you want to interact with the `tmux` multiplexer, you need to
press a specific key combination. That is referred to as the prefix key!

By default, the prefix key is `<C-b>`, which means that you press both the
`Ctrl` key and the `b` key. Pressing the prefix key means that you are now
entering `tmux` communication mode, and keys you press after that will be sent
to the multiplexer itself.

{:.highlight}
I prefer to use `<C-q>` as my prefix key, so I remap it in my configuration
file. See that config file section below for more information.

## Warning

Since you will be using `ssh` a lot to access the class server, please resist
the temptation to nest `tmux` sessions. By that we mean that you start a session
on your local machine, then ssh into the server, and then start another session
inside your local one.

That is bad for a multitude of reasons, and I don't think it's worth the pain of
trying to deal with nested `tmux` sessions. If you feel up for it, there's
plenty of tutorials and discussions about it online. I personally frown upon
nested `tmux` sessions.

Therefore, your normal workflow would be to ssh into the server, then start (or
resume) a `tmux` session there.

# Your first session

## Create a session

So let's get started. Login to the server and then start a `tmux` session as
follows:

  ```shell
  $ tmux new -s my_first_session
  ```

This will drop you into a new `tmux` session called `my_first_session` (that's
why the `s` flag is there). You will notice that a green status bar appears at
the bottom. This contains some useful information, you can see the full
documentation of that bar in the official documentation.

## Detach from the session

You can now run commands and do things just like you would do if you are running
on your native terminal window. Let's say you are done for now, but you don't
want to kill off your session, you want to save its state so that you can resume
it later on.

To do so, you can **detach** from a `tmux` session. The session will keep
running in the background and you can resume it at any time. Even better, if you
have a long running process running in there, it will continue running in the
background. So if for example, your code needs to run for an hour, you can do
the following:

1. Start a `tmux` session.
2. Start the process.
3. Detach from the session.
4. Do other stuff for an hour.
5. Resume the session and your process would have completed execution.
   Even more, if your process spits out stuff to standard output, you will be
   able to see all of that in there!

Now that I have convinced how great that is, let's detach from our session. To
do so, hit the prefix key, followed by the `q` key. For example, if you're still
using the default prefix, then you need to hit `<C-b> q`.

You will notice that your session will close and will be sent to the background.
You are now back in your native terminal window, and you can launch new
sessions, or resume other ones.

## Attach to a running session

Okay, now we would like to re-attach to the session we just closed. First, let's
check on the sessions that we have running. To do so, you can use the following:

  ```shell
  $ tmux ls
  csse132: 1 windows (created Sat Nov 25 10:36:34 2023)
  csse332: 2 windows (created Mon Nov 20 22:23:16 2023)
  my_first_session: 1 windows (created Sat Nov 25 23:12:09 2023)
  ```

You can see that in my output, I have three sessions:

1. One for `csse132`. It has one window.
2. Another for `csse332`. It has two windows.
3. A third, `my_first_session`, which is the one we just created.

To resume the session you want, simply use:

  ```shell
  $ tmux at -t my_first_session
  ```

The `-t` flag allows you to specify the name of the session you'd like to
resume. After issuing this command, you will be back in your `tmux` session and
you can resume where you left off, with your history and your standard output
preserved, as well as your current directory, running programs, open files, etc.

{.highlight}
A useful feature is that `tmux` does pattern matching when looking for a session
by name. So for example, for the above, I could have used `tmux at -t my_f`
and `tmux` would recognize that I am looking for `my_first_session`.

# Working with panes

Okay now that we have a session with its window, you can create panes to do
things across instances of your terminal, and eventually across several machines
via ssh.

## Creating panes

There are two main ways to create panes:

1. Horizontally: This will split your current pane into two _horizontally_. By
   default, the new pane will appear _on the right of_ your current pane.

2. Vertically: This will split your current pane into two _vertically_. By
   default, the new pane will appear _on the left of_ your current pane.

Go ahead and give it a try within your `my_first_session` session. Here are the
key combinations to do:

1. Hit `<prefix> %` to split __horizontally__.

2. Hit `<prefix> "` to split __vertically__.

Recall that `<prefix>` stands for your prefix key, which is `C-b` by default (or
`C-q` if you use my config).

## Navigating panes

To move from one page to another, simply use `<prefix> <arrow key>` to move in
the desired direction. For example:

1. `<prefix> ->` will move to the pane on the right of the active pane.

2. `<prefix> <-` will move to the pane on the left of the active pane.

You get the gist, same works for up and down arrow keys.

{:highlight}
Note that these movement keys wrap around, so moving down if there's nothing
below will wrap around to the one on top.

{:highlight}
In my config file, I remapped these combinations to use `vim`-like movement. So
for example, `<prefix> l` moves right, `<prefix> h` moves left, `<prefix> k`
moves up, and `<prefix> j` moves down. This keeps my fingers at the same
location on the keyboard (because I'm lazy!)

{:highlight}
If you hit `<prefix> q`, numbers will show on your panes with your active one
highlighted. If you press the corresponding number before the numbers disappear,
you will be moved to the pane with that number you entered.

# Terminating panes and windows

If you are done with a pane or window, simply kill the terminal running in that
pane or window, that will cause that pane or window to die out. If you exit the
last window running in a session, that session will be terminated as well.

If for some reason, your session hangs and you cannot kill it, you can ask
`tmux` to do it for you. From another terminal window, use:

  ```shell
  $ tmux kill-session -t my_first_session
  ```

# Navigating sessions and windows

If you have multiple sessions or windows, you can use this nice trick to move
between them.

Hit `<prefix> s`, this will drop you into a small menu from which you can choose
which one of your sessions you would like to switch to. You can also see a
preview of what is going on in that session to help you find out which one you
need.

Also, each session will have a nested list of all its windows, so you can move
to a specific window of a specific session by expanding that session's window
list and selecting the appropriate window.

# Moving forward

This is just a glimpse of what `tmux` can do, to get you started and get your
feet wet with navigating windows and panes. The more you master `tmux`, the
easier the labs will get!

The official `tmux` repository has a wonderful kickstart guide that goes a bit
further than what we go through here. Take a look at it
[here](https://github.com/`tmux`/`tmux`/wiki/Getting-Started).

# My config file

Just like any other tool, you can customize `tmux` to your desires. Below, I
have pasted my config file for your reference, feel free to use it or edit it as
you see fit.

To set up your config file, simply place your configuration options in a file
called `.tmux.conf` under your home directory. In other words, `vim
~/.tmux.conf`, add your options, save and exit. Reload `tmux` and you will be
good to go!

```tmux
# support colors with modern terminal emulators.
set -g default-terminal "screen-256color"

# vi key-mappings
set -g mode-keys vi

# only use the option below if you use zshell, if you're on bash, don't need it
# set-option -g default-shell /bin/zsh

# enable mouse scrolling in history.
set -g mouse on

# change the prefix key to C-q
set -g prefix C-q
unbind C-a
bind C-q send-prefix

# vim splits like switching
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# vim-like copy and paste in copy mode (for macosx)
bind P paste-buffer
bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi y send-keys -X copy-selection
bind-key -T copy-mode-vi r send-keys -X rectangle-toggle

# If above doesn't work on linux, comment them out and use these ones!
# bind-key -t vi-copy 'v' begin-selection
# bind-key -t vi-copy 'y' copy-selection
# bind-key -t vi-copy 'r' rectangle-toggle
```

