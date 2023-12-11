---
layout: page
title: Lab 2
last_modified_date: Mon Dec 11 2023
current_term: Winter 2023-24
nav_order: 30
parent: Labs
description: >-
  Setup and instructions for lab 2.
---

## Table of contents
{:.no_toc}

1. TOC
{:toc}

---

# Introduction

In this lab, we would like to extend our attack from lab 1 to mount a _Man in
the Middle_ (MITM) attack on two hosts on the same network. We will explore
further loopholes in the Address Resolution Protocol and use it to breach the
integrity and confidentiality of packets on the network.  This will also serve
as an introduction to IPv4 routing and the TCP handshake.

# Logistics

In addition to the tools we set up in the prelab, you will need the following:

1. [Wireshark](https://www.wireshark.org/) to visually see packets and
   protocols.
   - Install this on your local machine, so you can see things visually.
2. If you are comfortable with command line, you can also use `tshark` to
   observe the same packets and protocols, directly on the server machine.
3. `scp` or `rsync` will prove to be useful to obtain packet captures from the
   server and download them on your local machine. They should be installed by
   default on your Linux distribution that you are running.
4. `nc` (netcat) will help us set up a simple client-server application.

# Learning objectives

After completing this lab, you should be able to:

- Use `libpcap` to capture and manipulate packets on the wire.
- Compare performance between different implementations of exploits.
- Conduct a MITM attack on two hosts to act as a router.
- Explore IP routing and TCP set up.

# Getting the config

To start with this lab, login to the class server, and navigate to your
`netsec-labs-username` directory. Grab the latest updates using:

  ```shell
  (class-server) $ git fetch upstream
  (class-server) $ git pull upstream main
  ```

A folder called `lab2` should show up in your directory, that is where you
will do most of your lab.

## Patching the docker file

{.warning}
Before starting here, please make sure that your experiments from prelab2 are
down.  To do so, navigate back to the `prelab2` directory and do `docker compose
down`.

I have updated the patch script to no longer ask you for your username and
subnet, it will try to extract those on its own and print out your subnet (it is
the same on as the one announced on the Moodle page). Also, it now generates
scripts for you to connect to your hosts quickly.

To do so, in the `lab2` directory, run the patch script:

  ```sh
  (class-server) $ ./patch_docker_compose.sh
  Attempting to fetch subnet automatically...
  Found your subnet, it is 10.10.0
  Done...
  ```

If you had already patched your script, you will see something like this:

  ```sh
  (class-server) $ ./patch_docker_compose.sh
  Attempting to fetch subnet automatically...
  Found your subnet, it is 10.10.0
  [ERROR] ########################################################################
  [ERROR] # It looks like your docker-compose.yml file has already been patched. #
  [ERROR] #                                                                      #
  [ERROR] # If you are having issues bringing up the environment, it means it is #
  [ERROR] #  still in use.                                                       #
  [ERROR] #                                                                      #
  [ERROR] # Try to take down the experiment first, then bring it up again.       #
  [ERROR] #  To bring it down: docker compose down                               #
  [ERROR] #  To bring it up:   docker compose up -d                              #
  [ERROR] ########################################################################
  ```

If for some reason, the script fails to find your subnet, you can override its
behavior by providing your subnet on the command line:

  ```sh
  (class-server) $ ./patch_docker_compose.sh SUBNET
  ```

If all goes well, you should also see three new files in your directory:
`connct_hostA.sh`, `connect_hostB.sh`, and `connect_attacker.sh`. You can use
these scripts to directly connect to the desired host, without having to type
the whole `docker container exec -it` command. Finally, I have also adjust the
container's hostnames to make it easier for you to identify which is which.

For example, to connect to `hostA`, you can use:

  ```sh
	$ ./connect_hostA.sh
  ┌──(root㉿hostA)-[/]
  └─#
  ```

Hopefully, that would make things a bit easier for you.

{.highlight}
If you are enable to execute a script due to a permissions issue, then try the
following `$ chmod +x <script name.sh>` to make it executable and try again.

{:.warning}
In the remainder of this document, I will not be using your specific prefixes
and subnets. For example, when I refer to `hostA`, you should replace that with
`user-hostA` where `user` is your RHIT username. Similarly, I will be using
`10.10.0` as the default subnet, you should replace that in all ip addresses
with your own subnet. For example, if your subnet is `10.11.0`, then replace the
ip address `10.10.0.1` with `10.11.0.1`.

# Network topology

We will start off with a similar topology to that of lab1. We will have three
containers (recall to replace `10.10.0` with your subnet):

1. `hostA` with IPv4 address of `10.10.0.4`
2. `hostB` with IPv4 address of `10.10.0.5`
3. `attacker` with IPv4 address of `10.10.0.10`

{:.highlight}
Please note that the `attacker` container is configured to ignore ICMP Echo
request packets, and thus will not respond to `ping` requests.

They all exist on the same local network and can talk to each other freely. Our
target at the end of this lab is to make the `attacker` container sit in the
middle of `hostA` and `hostB`, such that any packet from A to B or B to A, will
be intercepted by the attacker; this is referred to as a _Man in the Middle
Attack_ (MITM).

Before the attack, the topology looks as follows:

  ![topo1]({{site.baseurl}}/assets/images/lab2/topo_benign.jpg)

After the attack, it should become:

  ![topo2]({{site.baseurl}}/assets/images/lab2/topo_bad.jpg)


---

# 1. Implementing ping

# 2. Disconnections the two hosts

# 3. Man in the Middle

