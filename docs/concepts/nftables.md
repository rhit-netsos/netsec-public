---
layout: page
title: Introduction to Firewalls
last_modified_date: Wed Jan 29 21:34:42 EST 2025
current_term: Winter 2024-2025
nav_order: 50
nav_exclude: false
parent: Concepts
description: >-
  Instruction to creating firewalls using nftables
---

## Table of contents
{:.no_toc}

1. no_toc
{:toc}

---

# Introduction

This lab serves as an introduction to using `nftables` to set up a stateless
firewall that can control which traffic is allowed into a subnetwork while
blocking other kinds of traffic. We will mostly focus on TCP traffic in this
lab, but the same concepts generalize to other protocols and applications.
We will focus first on packet filtering and then add on more applications in
later concept labs.

## Packet filtering

A packet filter is a piece of software that hooks into your network layer and
reads packet headers to determine whether such packets are allowed in the
system or not. At its most basic level, a packet filter makes one of two
decisions:

1. **ACCEPT** a packet, which means that packet can go through to the
   application or to be forward on another interface.

2. **DROP** a packet, which means that packet will be dropped from the system,
   and thus will not be allowed to move into your network stack.

Those two actions form the basis of a packet filter, however, much more
sophisticated applications can be created, such as performing _Network Address
Translation_ (NAT) and more involved firewall applications.

Packet filtering allows you to gain control over the network, deciding which
packets can go through and which ones will be dropped. It also allows for
visibility over your network, so you can track what traffic is coming in and
where it destined. All of this will serve the purpose of enhancing the
network's security. You can think of it as a bouncer that sits at your front
door and decides who is allowed to come through and knock and who will be
turned away directly.

# Learning objectives

At the end of this concept lab, you should be able to:

- Define how a firewall works in the context of a Linux box.
- Experiment with different filtering rules using `nftables`.
- Add `nftables` rules to restrict access to your private network for certain
  individuals and/or applications.

# Logistics

For this lab, we will be using GitHub classroom to get the starter code. Please
follow this [link](https://moodle.rose-hulman.edu/mod/url/view.php?id=4768799)
to accept the assignment and obtain your own fork of the lab repository.

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

1. `.env` (hidden file - use `ls -al` to see it) contains your UID and GID
   variables.

2. `connect_*.sh` a utility script to quickly connect to each container in this
   lab.

## Network topology

In this lab, our network topology is fairly simple. We have a client container
connected to a firewall container. On the other end sits a server that is
providing certain services to your client container. The firewall is acting
both as a router and a packet filter for your two subnetworks.

Here's a simple representation of this topology (Shamelessly generated using
`deepseek`):

```txt
+-------------------+          +-------------------+          +-------------------+
|      client       |          |     firewall      |          |      server       |
|  IP: 10.10.0.4    |          | eth0: 10.10.0.10  |          |  IP: 10.10.1.5    |
|  Interface: eth0  +----------+ eth1: 10.10.1.10  +----------+  Interface: eth0  |
+-------------------+          +-------------------+          +-------------------+
```

<!--
Each container has a root user with password `netsec`. Additionally, I have
added another unprivileged user with username `netsec` and password `netsec`.
-->

---

# Step 1: Map the running services

To start off, make sure that the `client` container can reach the `server`
container and vice versa. Simply `ping` the server from the client to make sure
that the network is up and running.

Our first step in protecting our network is understanding what services are
running on our network. Use `nmap` to uncover all services running on the
`server` container, that is the one we'd like to protect.

_Hint_: `server` is only running TCP services, so it should be quick and easy
to find out what services are running there.

## Question sheet

After running your `nmap` scan, answer the following questions:

1. List out the services running on the `server` container.

2. For each service running there, list a command that you can use to test if
   that service is running and reachable.

   _Hint_: Your containers can reach the Internet, so if you need some tools,
   feel free to install those using `sudo apt update && suod apt instal -y
   <tool package name>`.

# Step 2: Adding firewall rules

If you have done some form of networking before, then you must have heard of
`iptables` as a tool to use the Linux kernel's features to perform packet
tracing and filtering. While you could use `iptables` to perform everything we
need in this lab, we will be using the newer `nftables` to do so.

`nftables` leverages newer features in the Linux kernel (starting kernel >=
3.13) to provide similar functionalities to `iptables`, albeit with a better
(arguably) syntax and rule definition, reducing code duplication, and enhancing
performance.

{:.warning}
All of your firewall rules must happen on the `firewall` container. Do not add
or change any rules on the `client` or `server` containers.

{:.warning}
Please note that all the command below need escalated privileges, and thus use
the `sudo` command. However, please note that you can either login as root
(using `docker exec -it <container> /bin/bash`) or after using the
`./connect_*` script, use `sudo -s` to switch to the root account.

{:.warning}
Please note that if you are logged in as `root` and you edit or create any
files, then you might lose access to it outside of the container. To prevent
that from happening, edit your files from the virtual machine (not the
container). But if you happen to forget, you can always change the owner of
that file back to `netsec` using `chmod netsec file_path`.

## View current rules

On the `firewall` container, let's examine the current rules there. You can do
so using:
```sh
sudo nft list ruleset
```

On my setup, that showed something like the following:
```txt
# Warning: table ip nat is managed by iptables-nft, do not touch!
table ip nat {
        chain DOCKER_OUTPUT {
                ip daddr 127.0.0.11 tcp dport 53 counter packets 0 bytes 0 dnat to 127.0.0.11:45487
                ip daddr 127.0.0.11 udp dport 53 counter packets 0 bytes 0 dnat to 127.0.0.11:42559
        }

        chain OUTPUT {
                type nat hook output priority dstnat; policy accept;
                ip daddr 127.0.0.11 counter packets 0 bytes 0 jump DOCKER_OUTPUT
        }

        chain DOCKER_POSTROUTING {
                ip saddr 127.0.0.11 tcp sport 45487 counter packets 0 bytes 0 snat to :53
                ip saddr 127.0.0.11 udp sport 42559 counter packets 0 bytes 0 snat to :53
        }

        chain POSTROUTING {
                type nat hook postrouting priority srcnat; policy accept;
                ip daddr 127.0.0.11 counter packets 0 bytes 0 jump DOCKER_POSTROUTING
        }
}
```

You will notice that `docker` by default injected a bunch of rules to make sure
that your traffic does not leak out of the internal network and cause mayhem.

{:.warning}
Please do not mess with any of the docker rules as breaking those can lead to
sever connectivity issues and can also impact other users on our server.

## `nft` tables

The first abstraction when it comes to `nftables` is that of a **table**. A
table is a top level container of rulesets that holds chains, rules, maps, and
state objects. A packet can pass through several tables before being delivered
to the target application or forwarded on the network.

A table must be associated with exactly **one family**. In `nftables`, we
currently have several families:
1. `ip`: Filters IPv4 traffic.
2. `ip6`: Filters IPv6 traffic.
3. `inet`: Filters both IPv4 and IPv6 traffic.
4. `arp`: Filters ARP packets.
5. `bridge`: Filter traffic traversing bridged networks.
6. `netdev`: This one is a bit different, it allows to see and filter traffic
   right out of the Network Interface Card (NIC), i.e., as raw as possible.

In this lab, we will only concern ourselves with the `ip` family.

Let's first create a table for this lab, we'll call it `netsec_tbl`. To do so,
you can use:
```sh
sudo nft add table ip netsec_tbl
```
You can see here that first argument after `sudo nft add table` is the family to
which the table will belong (which is `ip` in our case), followed by the name
you'd like to give to that table.

Now, run `sudo nft list ruleset` to see that your table has been successfully
created. It will show up as empty for now. To only see our table, you can also
use `sudo nft list table netsec_tbl`.

Here are some other useful commands when it comes to tables (recall to always
use `sudo` if you are not logged in as root):

- To delete a table: `nft delete table ip netsec_tbl`.
- To remove all the rules in a table: `nft flush table ip netsec_tbl`.
- To see just the tables (without the chains and rules): `nft list tables`.

## `nft` chains

Each table will have one or more **chains**. Chains are sets of rules that are
to be applied to your packets at a specific location, specific by a **hook**
into the kernel's network stack. Unlike `iptables`, `nftables` does not have
predefined chains, you will add chains to your tables at the corresponding
hooks, which will only be considered if they are active, thus relieving the
kernel from being bogged down with unused chains.

To add a chain to your table, here's the generic syntax. Everything between
`<>` is an argument, while everything between `[]` is optional.

```sh
nft 'add chain [<family>] <table_name> <chain_name> { type <type> hook <hook>
priority <value> ; [policy <policy>] ; [comment "text comment"] ;}'
```
where:

- `<type>` is the type of your chain (see below).
- `<hook>` is the name of the hook where your chain will be inserted.
- `<priority>` is an integer representing the priority of your chain (relevant
  if you have multiple chains).
- `<policy>` is the default policy to be applied to packets on this chain
  **after all rules have been evaluated**.
- `text comment` is simply a comment you can put it to document your chain.

{:.warning}
Please note that the single quotes around the `add chain` command are mandatory
unless you want to escape all your semicolons and quotes (i.e., unless you use
the signal quotes, you'll have to write `\;` for semicolons and `\"` for quotes).

### Chain types

A chain can have one of three types. In this lab, we will only focus on the
`filter` type. We will discuss other types as we need them.

### Chain hooks

Each chain can be placed at a possible hook in the kernel. Here are the
possible values:

1. **ingress**: used only for `netdev` family. Basically this hooks right
   after your NIC driver.

2. **prerouting**: This hook sees all incoming traffic before any routing
   decision is made. For example, this sees traffic destined to the machine
   itself AND packet being forwarded to other devices on the network.

3. **input**: This hook sees packets that are addressed to the local system
   (for example, if someone pings the firewall, that packet will show up on the
   input hook).

4. **forward**: This hook sees packets that have been routed and are not
   destined to the local system.

5. **output**: This hook sees packets that are originating from the local
   system and are leaving it.

6. **postrouting**: This hook sees all packets that are leaving the system,
   regardless of whether they are origination from the local system or are
   being forwarded from somewhere else.

In this lab, we are mostly interested in the `prerouting`, `input`, `output`,
and `forward` hooks.

### Chain policy

The chain's base policy defines what happens when a packet reaches the end of a
ruleset and all the rules have decided to pass it through. Currently, there are
only two possible options, which are `accept` to keep the packet alive and
moving on and `drop` to drop the packet and discard it.

By default, the policy is `accept` unless otherwise specified.

### Chain priority

The chain priority is used to order your chains, i.e., which chains get applied
first. Chains with a lower priority (i.e., most negative) are run **before**
chains with positive priority value, and so on.

To see a list of hooks and default priorities, you can consult the `nftables`
[wiki page](https://wiki.nftables.org/wiki-nftables/index.php/Netfilter_hooks).

### Adding a new chain

Based on the above, let's go ahead and add our first chain. We'll call this one
netsec_in to catch packets coming into the firewall that are destined for the
firewall itself.

Before starting, try to reach the `firewall` container from the `client`
container through a simple `ping`. Make sure that both containers are able to
reach each other.

To add this chain, use:

```sh
sudo nft 'add chain ip netsec_tbl netsec_in { type filter hook input priority 0 ;
policy drop ; comment "my first chain" ; }'
```

To make sure your chain shows up in the table, you can use `sudo nft list table
netsec_tbl`. Mine looks like the following:

```txt
table ip netsec_tbl {
        chain netsec_in {
                comment "my first chain"
                type filter hook input priority filter; policy drop;
        }
}
```

### Question sheet

On your question sheet, answer the following question:

1. What do you expect the impact of the chain we have added to be?

2. Verify your answer by running a simple command from the `client` or the
   `server`.

3. How would you change the chain above to make sure that this behavior does
   not take place?

### Flushing and modifying chains

As we have seen, our `netsec_in` chain is not desirable, so we'd like to remove
it and replace it with a chain that produces more of what we want.

To do so, first you'll need to flush the chain to remove any rules in it using:

```sh
sudo nft flush chain netsec_tbl netsec_in
```

Then you can delete the chain using:

```sh
sudo nft delete chain ip netsec_tbl netsec_in
```

Verify that your chain has been deleted using `sudo nft list table netsec_tbl`.

### Adjust the chain

Before moving on, recreate the `netsec_in` chain with correct parameters so
that you can play with the packets that are coming into the firewall. Verify
that your chain does not lead to the behavior we observed earlier on.

{:.warning}
Please note that `nftables` tables, chains, and rules we define here are not
persistent, i.e., they will be removed if you restart your container. We will
talk about scripting in `nftables` in another concept lab.

