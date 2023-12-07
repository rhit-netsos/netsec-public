---
layout: page
title: Lab 2
last_modified_date: Wed Dec  6 22:35:50 2023
current_term: Winter 2023-24
nav_order: 20
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

# Learning objectives

After completing this lab, you should be able to:


# Getting the config

To start with this lab, login to the class server, and navigate to your
`netsec-labs-username` directory. Grab the latest updates using:

  ```shell
  (class-server) $ git fetch upstream
  (class-server) $ git pull upstream main
  ```

A folder called `lab2` should show up in your directory, that is where you will
do most of your lab.

## Patching the docker file

As we did in the prelab, you will need to patch the `docker-compose.yml` file to
be unique to your own experiment, and change addresses to use your assigned
subnet. Recall that your assigned subnet can be found on the Moodle page for the
class.

To do so, in the `lab1` directory, run the patch script as follows:

  ```shell
  (class-server) $ ./patch_docker_compose.sh user SUBNET
  ```
Replace `user` with your RHIT username and `SUBNET` with the subnet you got from
Moodle.

{:.warning}
In the remainder of this document, I will not be using your specific prefixes
and subnets. For example, when I refer to `hostA`, you should replace that with
`user-hostA` where `user` is your RHIT username. Similarly, I will be using
`10.10.0` as the default subnet, you should replace that in all ip addresses
with your own subnet. For example, if your subnet is `10.11.0`, then replace the
ip address `10.10.0.1` with `10.11.0.1`.

# Network topology


---

# Speedup

## Performance under C

```sh
PING 10.10.0.13 (10.10.0.13) 56(84) bytes of data.
64 bytes from 10.10.0.13: icmp_seq=1 ttl=64 time=12.6 ms
64 bytes from 10.10.0.13: icmp_seq=2 ttl=64 time=2.88 ms
64 bytes from 10.10.0.13: icmp_seq=3 ttl=64 time=0.931 ms
64 bytes from 10.10.0.13: icmp_seq=4 ttl=64 time=4.00 ms
64 bytes from 10.10.0.13: icmp_seq=5 ttl=64 time=2.93 ms
64 bytes from 10.10.0.13: icmp_seq=6 ttl=64 time=0.946 ms
64 bytes from 10.10.0.13: icmp_seq=7 ttl=64 time=4.03 ms
64 bytes from 10.10.0.13: icmp_seq=8 ttl=64 time=2.93 ms
64 bytes from 10.10.0.13: icmp_seq=9 ttl=64 time=0.963 ms
64 bytes from 10.10.0.13: icmp_seq=10 ttl=64 time=7.93 ms

--- 10.10.0.13 ping statistics ---
10 packets transmitted, 10 received, 0% packet loss, time 9029ms
rtt min/avg/max/mdev = 0.931/4.008/12.555/3.466 ms
```

## Performance under python

```sh
PING 10.10.0.13 (10.10.0.13) 56(84) bytes of data.
64 bytes from 10.10.0.13: icmp_seq=1 ttl=64 time=96.7 ms
64 bytes from 10.10.0.13: icmp_seq=2 ttl=64 time=24.0 ms
64 bytes from 10.10.0.13: icmp_seq=3 ttl=64 time=30.9 ms
64 bytes from 10.10.0.13: icmp_seq=4 ttl=64 time=33.0 ms
64 bytes from 10.10.0.13: icmp_seq=5 ttl=64 time=32.0 ms
64 bytes from 10.10.0.13: icmp_seq=6 ttl=64 time=30.9 ms
64 bytes from 10.10.0.13: icmp_seq=7 ttl=64 time=33.2 ms
64 bytes from 10.10.0.13: icmp_seq=8 ttl=64 time=31.6 ms
64 bytes from 10.10.0.13: icmp_seq=9 ttl=64 time=17.9 ms
64 bytes from 10.10.0.13: icmp_seq=10 ttl=64 time=24.0 ms

--- 10.10.0.13 ping statistics ---
10 packets transmitted, 10 received, 0% packet loss, time 9014ms
rtt min/avg/max/mdev = 17.937/35.435/96.741/20.985 ms
```

