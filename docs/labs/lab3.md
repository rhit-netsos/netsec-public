---
layout: page
title: Lab 3
last_modified_date: Mon Jan 15 2024
current_term: Winter 2023-24
nav_order: 40
parent: Labs
description: >-
  Setup and instructions for lab 3.
---

## Table of contents
{:.no_toc}

1. TOC
{:toc}

---

# Introduction

In this lab, we will apply the concepts we learned in the last couple of
concept labs to hijack an active `telnet` TCP connection between a client and a
server. Before starting this lab, make sure you have a solid grasp on the TCP
concept lab and the reverse shell concept lab.

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

- Hijack an active TCP connection to execute arbitrary command on a remote
  server.
- Create a reverse shell to be able to exfiltrate data from the remote server.

# Getting the config

To start with this lab, login to the class server, and navigate to your
`netsec-labs-username` directory. Grab the latest updates using:

  ```shell
  (class-server) $ git fetch upstream
  (class-server) $ git pull upstream main
  ```

A folder called `hijack` should show up in your directory, that is where you
will do most of your lab.

## Patching the docker file

{.warning}
Before starting here, please make sure that your experiments from previous labs
are down.

{.warning}
The subnets for this lab have changed, so do not worry if you see different
subnets show up for your containers.

I have updated the patch script to no longer ask you for your username and
subnet, it will try to extract those on its own and print out your subnet (it is
the same on as the one announced on the Moodle page). Also, it now generates
scripts for you to connect to your hosts quickly.

To do so, in the `hijack` directory, run the patch script:

  ```sh
  (class-server) $ ./patch_docker_compose.sh
  Attempting to fetch subnet automatically...
  Found your subnet, it is 10.10
  Done...
  ```

If you had already patched your script, you will see something like this:

  ```sh
  (class-server) $ ./patch_docker_compose.sh
  Attempting to fetch subnet automatically...
  Found your subnet, it is 10.10
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

{:.highlight}
If you are enable to execute a script due to a permissions issue, then try the
following `$ chmod +x <script name.sh>` to make it executable and try again.


# Network topology

Our topology for this lab is fairly simple. We start off with three machines, a
client and a router interface on one subnet, a server and an interface on the
same router on the other subnet. The client typically establishes a `telnet`
session with the server to be able to run remote commands.

At one point, an attacker compromises the router and would like to mount a TCP
session hijacking attack to run arbitrary commands on the server.

---

# 1. Testing things

Under the `volumes` directory, you will find the `src/route` directory. This is
where all of your code should live. I have already provided you with code that
does routing on the attacker, so you don't have to worry about that. All of
your packet injection code can be found in the file `hijack_conn.c`.

There is only one thing you need to edit in `route.c` and that is the IP and
MAC addresses for your client and server containers. You will find those at the
top of file as such:

```c
#define SERVER_IP "10.10.1.15"
#define SERVER_MAC "02:42:0a:0a:01:0f"

#define CLIENT_IP "10.10.0.4"
#define CLIENT_MAC "02:42:0a:0a:00:04"
```

Please adjust those values to match your own configuration, and then compile
the code using `make` in the `route` directory. A `route.bin` executable will
show up.

## Testing basic routing

To make sure everything starts off correctly, bring up your environment using:
```sh
docker compose up -d
```
and then grab a terminal at the client and **two** on the attacker.

The routing code will have to run in two separate processes since we would like
to handle bi-directional communication. Therefore, in one attacker terminal
window run:
```sh
cd /volumes/src/route/
./route.bin -i eth0 -o eth1
```
and on another attacker terminal, run
```sh
cd /volumes/src/route/
./route.bin -i eth1 -o eth0
```

This will instruct the `route.bin` program to listen on both interfaces to make
sure you can forward traffic correctly.

From the client terminal, try to reach the server first using `ping`:
```sh
ping -c 10.10.1.15
```
{:.highlight}
Remember to replace `10.10.1.15` with your server's IP address.

If the `ping` is successful, you should be good to go. Otherwise, please
contact me as soon as possible to debug. After that, create a `netcat` service
on the server container and try to connect to it from the client. If all goes
well, you are good to go to the next step.

# 2. Inject a command

Your task in this lab is to inject an arbitrary command on the server container
by hijacking an already existing `telnet` connection over TCP between the
client and the server. You do not have to worry about establishing the
connection, you can just sit and watch for traffic until you see one. For
simplicity's sake, we will assume that a connection is established, so you
don't have to detect one. In other words, treat all TCP packets seen on the
attacker router as part of a `telnet` connection.

## A good reference point

Before moving forward, I strongly suggest that you grab a packet capture of a
simple `telnet` session between the client and the server (pretty much what we
did in the TCP concept lab) and keep a copy of that packet capture, it will
prove to be useful later on.

## The attack

For this part of the lab, your goal is to have the server execute the command
`touch /volumes/pwnd.txt` by hijacking the `telnet` session coming from the
client. Your attack is successful is the file `pwnd.txt` appears on the
server's disk after you inject your packets.

For simplicity, we will assume that our attack will only be triggered after the
user has entered a specific command on the `telnet` session. For me, I chose to
trigger my exploit when the user entered `ls`, feel free to choose whichever
trigger command you find suitable.

In the source code, under `route.c`, navigate to line 108, you will find the
following statement:
```c
// check if it's a TCP packet and if we can use it to hijack the connection.
if(iphdr->protocol == IPPROTO_TCP) {
  // grab a tcp header
  tcp = (struct tcphdr*)(pkt + sizeof(struct ether_header) + sizeof(struct iphdr));
  tcp->check = compute_tcp_checksum(tcp, iphdr);
  if(tcp->psh && tcp->ack) {
    // push & ack packet, works for telnet
    if(is_triggered(iphdr, tcp)){
      hijack_tcp_connection(fwd_handle, pkt, pktlen, iphdr, tcp, "touch /volumes/pwnd.txt");
    }
  }
}
```
This piece of code check if a TCP packet has been detected, and then computes
its checksum value. However, if the packet contains both `PUSH` and `ACK`
flags, we will check for the specific trigger using `is_triggered` and then
launch the attacker using `hijack_tcp_connection`.

The function `is_triggered` and `hijack_tcp_connection` can be found in the
`hijack_conn.c` file. This is where you will add your code. I have already
provided you with a skeleton of what you need to do along with a bunch of
`TODO` statements where you need to add your edits.

Start by writing your own `trigger` function and then launch the attack by
modifying the `hijack_tcp_connection` function.


