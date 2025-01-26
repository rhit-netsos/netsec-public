---
layout: page
title: Introduction to Network Reconnaissance
last_modified_date: Sun Jan 26 15:14:26 EST 2025
current_term: Winter 2024-25
nav_order: 20
parent: Concepts
nav_exclude: false
description: >-
  Instructions for perform network reconnaissance
---

## Table of contents
{:.no_toc}

1. no_toc
{:toc}

---

# Introduction

In this concept lab, we will introduce network reconnaissance as a way to find
what hosts are on the network, and, which service are those hosts running. We
will also do some network reverse engineering to find and exploit a
vulnerability in a network configuration and services.

# Learning

At the end of this concept lab, you should be able:

- Use `nmap` for basic network reconnaissance.
- Reverse engineer a network service by sending packets on the network and
  analyzing them.
- Construct an exploit based on the observed vulnerabilities in the network.

# Logistics

For this lab, we will be using GitHub classroom to get the starter code. Please
follow this [link](https://moodle.rose-hulman.edu/mod/url/view.php?id=4766168)
to accept the assignment and get your own fork of the lab repository.

{: .important }
The first time you accept an invitation, you will be asked to link your account
to your student email and name. Please be careful and choose your appropriate
name/email combination so that I can grade appropriately.

## Generating your `.env` file

Before we spin up our containers, there are some configuration variables that
must be generated on the spot. To do so, please run the `gen_env_file.sh`
script from the prelab repository directory as follows:

```shell
$ ./gen_env_file.sh
```

If run correctly, several files will be generated:

1. `.env` (hidden file — use `ls -al` to see it) contains your UID and GID
   variables.

2. `connect_*.sh` a utility script to quickly connect to each container in this
   lab.

## Network topology

The topology for this mini lab consists of three machine on the same local
network:

1. `client` with IPv4 address `10.10.0.4`.

2. `server` with IPv4 address `10.10.0.5`.

3. `attacker` with IPv4 address `10.10.0.24`.

---

# Overview

This experiment consists of three machines, a client, a server, and an attacker
machine. Unlike other labs, you will only have access to the attacker machine,
i.e., all of your code and commands will be run from the attacker, without
direct access to the client and the server.

All three containers are on the same subnetwork, their IP addresses are known
and static, and you can see those in the `docker-compose.yml` file . However,
the client and the server are running a network service that you do not have
access to, and your goal in this lab is to use tool to discover what that
service is, and then exploit it to flood the network with bogus packet by only
sending a few packets.

To do so, you will need to do the following:

1. Discover open ports on each machine. To help you out, the service is running
   on the same port in both client and server. Also, to help save you time, the
   service is running over UDP.

2. Reverse engineer the service by interacting with it, and then finding
   vulnerabilities in the service.

3. Exploit the running service to have both client and server flood the network
   with packets triggered by a few number of packets that you send out.

## Step 1: Network reconnaissance

To perform network reconnaissance, we will use a tool called `nmap`. At its
core, `nmap` will send out packets on the network and try to analyze any
responses it gets so that it can determine what hosts are alive, what services
are they running, which operating system they're running, and so on. In our
case, we already know what hosts exist on the network, we need to discover what
UDP services they have running. Therefore all what we are interested in running
a UDP _port scan_.

To save you some time on a lengthy port scan, here are some things we know
about the service that would make your port scan more targeted:

1. The service is running UDP on both client and server.

2. The service is running on the same port in both client and server.

3. The port number the service running on is non-standard, it is in the range
   8800 to 9100.

Port scans using `nmap` generally take a while, so make sure to adopt a good
targeted strategy to find any open and active UDP ports on either container.

`nmap` is already installed on the attacker container, you can find a good
`nmap` cheat sheet at the following
[link](https://hackertarget.com/nmap-cheatsheet-a-quick-reference-guide/).

## Step 2: Reverse engineering

Once you find the port on which the service is running, it is now the time to
reverse engineer the service. Use any tool or programming language to interact
with the service at its given port, and attempt to reverse engineer what the
service is doing.

{:.highlight}
Don't overthink it, the service is pretty simple and doesn't do anything smart.
Just practice crafting packets and making sense of what you see and receive if you
do send them out.

Once you understand what the service is doing, it should be pretty obvious that
it has a big apparent flaw (recall that it is running on both client and
server).

## Step 3: Exploit the service

Now that we know what the service is doing and how we can exploit it, write a
simple script to trigger the exploit. To help you out, if your exploit is
successful, both the client and the server will flood the network with large
packets forever. Without killing the services (or the containers), there is no
way to stop the packets coming in.

The only constraint we have on your attack is that it must send few packets
compared to the impact it will have on the network. We refer to such attacker
at **amplification attacks**.

Feel free to use any programming language you find easier for you, we don't
have much a performance constraint in this case.

