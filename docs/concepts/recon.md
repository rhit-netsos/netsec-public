---
layout: page
title: Introduction to Network Reconnaissance
last_modified_date: Thu Jan 11 11:20:38 2024
current_term: Winter 2023-24
nav_order: 20
parent: Concepts
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
what hosts are on the network, and which service are those hosts running. We
will also do some network reverse engineering to find and exploit a
vulnerability in a network configuration and services.

# Learning

At the end of this concept lab, you should be able:

- Use `nmap` for basic network reconnaissance.
- Reverse engineer a network service by sending packets on the network and
  analyzing them.
- Construct an exploit based on the observed vulnerabilities in the network.

# Logistics

## Getting the configuration

To start with this concept lab, login to the class server, and navigate to your
`netsec-labs-username` directory. Grab the latest updates using:

  ```shell
  (class-server) $ git fetch upstream
  (class-server) $ git pull upstream main
  ```

A folder called `recon` should show up in your directory, that is where you
will do most of your lab.

## Patching the docker file

{:.warning}
Before starting here, please make sure that your experiments from all other
labs are down.  To do so, navigate back to the latest lab directory and do
`docker compose down`.

I have updated the patch script to no longer ask you for your username and
subnet, it will try to extract those on its own and print out your subnet (it
is the same on as the one announced on the Moodle page). Also, it now generates
scripts for you to connect to your hosts quickly.

To do so, in the `recon` directory, run the patch script:

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

If all goes well, you should also see two new files in your directory:
`connct_client.sh` and `connect_server.sh`. You can use these scripts to
directly connect to the desired host, without having to type the whole `docker
container exec -it` command. Finally, I have also adjust the container's
hostnames to make it easier for you to identify which is which.

For example, to connect to `client`, you can use:

  ```sh
	$ ./connect_client.sh
  ┌──(root㉿client)-[/]
  └─#
  ```

Hopefully, that would make things a bit easier for you.

{:.highlight}
If you are unable to execute a script due to a permissions issue, then try the
following `$ chmod +x <script name.sh>` to make it executable and try again.

{:.warning}
In the remainder of this document, I will not be using your specific prefixes
and subnets. For example, when I refer to `client`, you should replace that with
`user-client` where `user` is your RHIT username. Similarly, I will be using
`10.10.0` as the default subnet, you should replace that in all IP addresses
with your own subnet. For example, if your subnet is `10.11.0`, then replace the
IP address `10.10.0.1` with `10.11.0.1`.

---

# Overview

This experiment consists of three machines, a client, a server, and an attacker
machine. Unlike other labs, you will only have access to the attacker machine,
i.e., all of your code and commands will be run from the attacker, without
direct access to the client and the server.

All three containers are on the same subnetwork and their IP addresses are
known and static, you can see those in the `docker-compose.yml` file (after you
have patched it). However, the client and the server are running a network
service that you do not have access to, and your goal in this lab is to use
tool to discover what that service is, and then exploit it to flood the network
with bogus packet by only dropping in a very small number of packets.

To do so, you will need to do the following:

1. Discover open ports on each machine. To help you out, the service is running
   on the same port in both client and server. Also, to help save you time, the
   service is running over UDP.

2. Reverse engineer the service by interacting with it, and then finding
   vulnerabilities in the service.

3. Exploit the running service to have it the client and the server flood the
   network with packets triggered by a very small number of packets that you
   send out.

## Step 1: Network reconnaissance

To perform network reconnaissance, we will use a tool called `nmap`. At its
core, `nmap` will send out packets on the network and try to analyze any
responses it gets so that it can determine which hosts are alive, what services
are they running, which operating system they're running, and so on. In our
case, we already know which hosts exist on the network, we need to discover
what UDP services they have running. Therefore all what we are interested in
running a UDP _port scan_.

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
simple script to trigger the exploit. To help you out, if you exploit is
successful, both the client and the server will flood the network with large
packets forever. Without killing the services (or the containers), there is no
way to stop the packets coming in.

The only constraint we have on your attack is that it must send a very small
number of packets compared to the impact it will have on the network. We refer
to such attacker at **amplification attacks**.

Feel free to use any programming language you find easier for you, we don't
have much a performance constraint in this case.

