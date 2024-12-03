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

<!--
To help you do your labs, we have a created a somewhat beefy server to host your
virtual networks. You can reach that server at `490-01.csse.rose-hulman.edu`
via `ssh` on port 22. To login, you can use your Rose-Hulman credentials. It is
preferable if you set up password-less access via public/private key
authorization.
-->

To help you do your labs, we have set up each with an individual virtual
machine running on the Rose-Hulman cluster. You can view your virtual machines
assginment on the spreadsheet on [Moodle]({{site.moodle_link}}).

On the spreedsheet, you will see that your login is always `csse`. Each virtual
machine has a default password (listed in the spreadsheet) that you can use to
login the first time. After your first login, you will be asked to change your
password to protect your access to the virtual machine.

{:.warning}
If you are off-campus, you will need to be on the campus virtual private network
(VPN) to be able to access the server. Please see the EIT documentation for how
to set up your VPN access.

{:.warning}
Your servers perform daily backup at night. If at any point in time you seem to
have things broken, please do let me know asap so we can recover your last
backup.

# Check your access

First, try to login to the server and make sure that you are able to see your
home directory. As a generic case, I will assume to be using
`490-01.csse.rose-hulman.edu` as my virtual machine, but please replace it
with your own virtual machine FQDN in the below instructinos.

To do so, use the following:

  ```shell
  $ ssh csse@490-01.csse.rose-hulman.edu
  ```

If you can login successfully, check your home directory.

  ```shell
  $ echo $HOME
  ```
And you should see your home directory look like `/home/csse/`.

# Generate your keys

To avoid having to constantly type your password to login, let's set you up
with a public/private keypair for authentication on the server.

## Generate a public/private keypair

If you already have generated a public/private keypair for any other purpose
before, then you can skip this section.

If not, then do the following (on your local Linux machine, not on the server!).

  ```shell
  $ ssh-keygen
  ```

Choose the default directory, and then select a passphrase to protect your key
(you can elect to leave it blank if you'd like).

Check that your key exists by reading the public key:

  ```shell
  $ cat ~/.ssh/id_rsa.pub
  ```

You should see a bunch of nonsense show up on your screen.

{: .highlight }
If you are using a newer version of `open-ssh`, your default key generation
will use a different algorithm. So your public key might be named something
like `id_ed25519.pub`. Please use whatever public key you were able to
generate.

## Copy keys to server

Now, copy your public key to the class server using:

  ```shell
  $ ssh-copy-id csse@490-01.csse.rose-hulman.edu
  ```

{:.warning}
If you have multiple keys on your local machine, you might need to specify one
to copy. You can use the `-i` switch with `ssh-copy-id`.

## Test login

Now, try to login to the server again using

  ```shell
  $ ssh csse@490-01.csse.rose-hulman.edu
  ```

You should not be prompted for your password again.

# The config file

Typing that long-ass server address every time you want to login to the server
is tedious. Let's do better and make it nice.

In an editor, on your local Linux machine, open the file `~/.ssh/config` and add
the following:

  ```txt
  Host netsec
    HostName 490-01.csse.rose-hulman.edu
    User csse
  ```

This basically let's `ssh` know that `netsec` is an alias for our class server,
at port 22, with your username. To verify that you can do things correctly, try:

  ```shell
  $ ssh netsec
  ```

You should now land in the class server, in your home directory, without any
trouble.

# A note on GitHub keys

You will be doing much of your editing on the class server, so it might be worth
it to generate a public/private keypair to use with GitHub for authentication.
Please checkout the official GitHub documentation for more information, but
here's a quick summary.

On the class server, while logged in:

1. Use `ssh-keygen` to generate a new pair of keys.
2. Use `cat ~/.ssh/id_rsa.pub` to read your public key.
3. Copy the public key from the terminal window.
4. Add the public key to the list of ssh keys on your GitHub profile.

Now you can clone your private repositories and push to them from the class
server.

# Customization

I have set up all of the virtual machines with some customization options to
help make your life easier in the class. You will be running `zsh` with a few
plugins to help development and testing.

I have added custom configuration scripts for `neovim`, `tmux`, and `zsh` that
get loaded by default. If you wish to turn off any of thease features, then
please let me know and I can reset your environment.

I have also added a bunch of aliases that will prove to be useful when working
with docker. We will reference those as we go along the labs.

<!-- TODO: Add stuff about the tmux files and neovim/vim configurations. -->

<!--
# Get your config files

Finally, let's get your `vimrc` and `tmux.conf` files on the server. If you
already use your own, feel free to customize your home shell as you see fit. If
you'd like to use the minimal ones I provide, follow the steps below.

## Getting `vimrc`

Get the `vim` config file and place it in your home directory on your server
home.

  ```shell
  $ wget -O ~/.vimrc https://www.rose-hulman.edu/class/csse/csse332/current/assets/files/vimrc
  ```

You should be good to use `vim`.

## Getting `tmux.conf`

Similarly, let's grab the default `tmux` config onto the server home directory.

  ```shell
  $ wget -O ~/.tmux.conf https://netsos.csse.rose-hulman.edu/courses/netsec/assets/files/tmux.conf
  ```
-->

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

