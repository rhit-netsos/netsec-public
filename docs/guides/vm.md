---
layout: page
title: Class server access
last_modified_date: Tue Nov 28 00:07:43 2023
current_term: Winter 2023-24
nav_order: 20
parent: Guides
description: >-
  Class server access instructions.
---

## Table of contents
{:.no_toc}

1. TOC
{:toc}

---

# Class server

To help you do your labs, we have a created a somewhat beefy server to host your
virtual networks. You can reach that server at `netsec-01.csse.rose-hulman.edu`
via `ssh` on port 22. To login, you can use your Rose-Hulman credentials. It is
preferable if you set up password-less access via public/private key
authorization.

{:.warning}
If at any point in time, you feel that the server is unresponsive or running too
slowly, please do let me know asap so we can whip up another one and distribute
the load between the two.

{:.warning}
If you are off-campus, you will need to be on the campus virtual private network
(VPN) to be able to access the server. Please see the EIT documentation for how
to set up your VPN access.

# Generate your keys

# Copy keys to server

## Test login

# The config file

# A note on GitHub keys

# Get your config files

## Getting `vimrc`

## Getting `tmux.conf`

## Even better

To keep all of your configuration files in sync, I highly recommend that you
take a look at [homeshick](https://github.com/andsens/homeshick). It is very
versatile tool that allows you to preload your config file on every new machine
within a couple of minutes.

# Need software?

You will notice that you do not have privileged execution on the server (i.e.,
you cannot use `sudo`), and that is for good reason. If you require software to
be installed that you cannot compile locally and append to your path, then
please let me know as soon as possible and I will investigate our options. If
everyone would benefit from the software, then we'll probably install it
server-wide. If it is only beneficial for you, then I will probably work with
you on compiling it locally and updating your `PATH` variable.

