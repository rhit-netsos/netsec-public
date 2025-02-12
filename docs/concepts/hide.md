---
layout: page
title: Hiding a network service
last_modified_date: Wed Feb 12 14:46:10 EST 2025
current_term: Winter 2024-25
nav_order: 80
parent: Concepts
lab_dir: hide
nav_exclude: false
description: >-
  Introduction to service isolation
---

## Table of contents
{:.no_toc}

1. no_toc
{:toc}

---

# Introduction

In lab 4, we established a port knocking sequence that allowed us to ask a
client to know a certain secret sequence of ports that they must hit before
being allowed to access a given port. However, the problem with that is we have
no way to authenticate that however knows the port sequence is actually someone
we can trust; they might have beaten the sequence out of someone we know, and
now they can access our hidden service. Furthermore, once our sequence is
compromised, changing that sequence and letting everyone know becomes a
problem.

Therefore port knocking without authentication is an issue that we must
address. In this concept lab, we will examine one possible way to hide services
by using other authenticated services.

# Learning objectives

At the end of this lab, you should be able to:

- Examine a way to hide a web service behind a firewall while only allowing
  authenticated services through it.

# Logistics

For this lab, we will be using GitHub classroom to get the starter code. Please
follow this [link](https://moodle.rose-hulman.edu/mod/url/view.php?id=4783832)
to accept the assignment and obtain your own fork of the lab repository.

{: .important }
The first time you accept an invitation, you will be asked to link your account
to your student email and name. Please be careful and choose your appropriate
name/email combination so that I can grade appropriately.

## Generating your `.env` file

Before we spin up our containers, there are some configuration variables that
must be generated on the spot. To do so, please run the `gen_env_file.sh`
script from the lab repository directory as follows:

```shell
$ ./gen_env_file.sh
```

If run correctly, several files will be generated:

1. `.env` (hidden file - use `ls -al` to see it) contains your UID and GID
   variables.

2. `connect_*.sh` a utility script to quickly connect to each container in this
   lab.


## Network topology

In this lab, we have a web server protected by a firewall and a client sitting
on a different subnet trying to reach the server.

 ```
                                                       | ----------- |
                                              -------- | Workstation |
                                              |        | ----------- |
                                              |
 | ------ |                | -------- |       |        | ------ |
 | Browser| -------------- | Firewall | -------------- | Server |
 | ------ |  10.10.0.0/24  | -------- |  10.10.1.0/24  | ------ |
 ```

---

# Overview

The goal of this concept lab is to able to obtain a secret from a webserver
running on port 80 on the `server` container. However, we are only allowed to
access the server from the `browser` container, i.e., all of your actions must
be done by first accessing the `browser` container.
<!-- The password you obtain will be the key to unlocking the next lab. -->

Unfortunately, the `firewall` between the browser and the server drops all
traffic destined to the `server` and only allows traffic going through to the
`workstation` container. This necessarily means that the `server` cannot
communicate with anyone not on the same subnet. In fact, it does not know how
to do so since we removed all routing entries from the server's routing table.

Therefore, the goal in this concept lab is to extract the secret message from
the `server` starting from your main entry point in the `browser` container.

# Step 1: Network discovery

First, we'd like to find out what services are running in the protected subnet.
If your try to use `nmap` on the server container, you will not be able to
reach it since the firewall will drop all packets going in that direction. If
you try to use `nmap server`, the report is going to come back with `Host seems
down.` since none of the packets will be able to reach it.

So our only option is to work with the `workstation` container. First, try to
run an `nmap` scan on the container, but we'd need to scan all possible `TCP`
ports open. To do so, you can use the `-p` flag in `nmap` as follows:

```sh
sudo nmap -p 1-65535 workstation
```

This will launch a scan on all possible ports (1 through 65535) using the `TCP`
protocol. Your report should show that there is one port open, but that the
service running on that port is `UNKNOWN`. Therefore, we must find out what
service is running on that port (make note of the port, you'll need it later
on).

## Task: Discovering network services

`nmap` is equipped with a way to discover services running on non-traditional
ports (we know 80 is HTTP, 443 is HTTPS, and so on, but we don't know the other
ones). Your first task is to look through the `nmap` documentation and trigger
`nmap` to run a service discovery on the `workstation` container in order to
find out the service running on that TCP port; it is really a simple flag you
pass to `nmap`.

In addition, we'd like to know how `nmap` does its service discovery. To do so,
do the following:

1. Grab two terminals on the `browser` container. In one, run `tcpdump` to
   capture tcp packets leaving the machine as follows: `sudo tcpdump -i eth0
   tcp -w /volumes/discovery.pcap`.

2. On the other terminal window, start the `nmap` service discovery. Since we
   know which port we are targeting, we don't really need to run another scan,
   we can just focus on that specific port. To do so, you can change the
   argument for the `-p` flag in the example above to be on specific port
   (instead of the 1-65535 range we gave before).

   Combine that with the service discovery flag and `nmap` will tell you which
   service is running on that weird port.

### Question sheet

On the lab question sheet, answer the following question:

1. Which port is open on the `workstation` container? And what service is it
   running?

2. Observe the network traffic capture during network discovery, how did `nmap`
   figure out what service is running on that port on `workstation`?

# Step 2: Extracting the secret

Now that you know what service is running on the `workstation` container, it
should be easy to figure out what to access the server and obtain the secret.
Note that you will need to interact with the server to obtain that secret
message, so the `workstation` container is equipped with a terminal-based web
browser called `lynx`. To access a web page and interact with it (for example
google.com), you can simply launch it as follows: `lynx www.google.com` and you
will be dropped into an interactive interface.

{:.highlight}
You might need to read a man page to figure out how to properly access the
service running on the `workstation` container.

{:.highlight}
_Hint_: If it sounds simple, it's because it is, you don't need to write any
scripts or launch any attacks here.

## Question sheet

After you have successfully extracted the secret, please answer the following
questions:

1. Please write down the command you used to access the service along with the
   secret message you extracted.

2. Our goal in this setup is to hid port 80 on the `server` from the outside
   world, unless you have some form of authentication happening first. However,
   accessing a browser window from the terminal is not ideal (imagine accessing
   banner from `lynx`!).

   If you were to solve this problem, how would you approach hiding port 80 on
   the server from unauthenticated users, while still allowing users with
   correct permissions to send packets to port 80?

   {:.warning}
   Note that we are not doing web-based authentication here, we would like to
   hide the entire server machine, i.e., no traffic should reach the server
   unless you have the proper authentication.

