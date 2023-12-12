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

We will start off with implement `ping` again, just to learn how to send packet
using `libpcap`. In your `lab2` directory, navigate to `volumes/src/ping` and
look at the source code in there.

The code is structured in the following manner:

1. `ping.c`: This contains the `main` function that listens for packets and
   captures them. Check out the `build_filter_expr` function in there. It build
   a filter expression for `libpcap` to only capture `icmp` packets that are
   __not originating__ for the machine running the script. This will help avoid
   infinite loops (Think about why that might happen?)

   You will not need to edit this file.

   `ping.c` externs a function called `parse_ip`. You can find that function in
   `parse_ip.c`.

2. `parse_ip.c`: This file contains the `parse_ip` function. In here, you should
   only check if the IPv4 header contains an ICMP subsequent header.

   This file externs a function called `parse_icmp.c` that would handle ICMP
   headers.

3. `parse_icmp.c`: This file is where most of what you want to do will happen.
   This is where we will extract an ICMP header and then reply to an Echo
   request if any.

You shall only edit the code in `parse_ip.c` and `parse_icmp.c`. The reason why
we set them up in this way is to make it easy for you to grab code from here and
use it in other parts of the lab.

## Task 1: Grabbing the ICMP header

You first task is to trigger the `parse_icmp` function to execute. You should
edit the `parse_ip.c` file to do the following:

1. Check if the IPv4 header contains an ICMP protocol.
2. If so, call `parse_icmp`. The arguments for `parse_icmp` are documented in
   the function's signature at the top of the file.

This task should not be more than two line of code.

## Task 2: Parse the ICMP header

Grab two terminals, one connected to `hostA` and another connected to
`attacker`, and try to ping the `attacker` from `hostA`, you will see that the
`attacker` does not reply. Our goal here is to change that.

  ```sh
  (netsec-01) $ ./connect_hostA.sh
  ┌──(root㉿hostA)-[/]
  └─# ping -c1 attacker
  PING attacker (10.10.0.10) 56(84) bytes of data.

  --- attacker ping statistics ---
  1 packets transmitted, 0 received, 100% packet loss, time 0ms
  ```

First thing, let's detect an ICMP Echo request on the `attacker`'s machine. 

### Step 1: Print the receipt of an ICMP Echo request

First thing to do is to acknowledge the receipt of an ICMP Echo Request, and
print from where it is coming from. Edit `parse_icmp.c` to do just that.

You will need to check the type of the ICMP header received, and then just print
the originating source IPv4 address of the packet; Hints are in the comments for
step 1 under the `TODO` label.

{:.highlight}
Note that to run `./ping.bin`, you will need to provide the MAC address of the
interface on which you should be running. To do so, you can either write it
manually, or you can read it from the system. Each interface's MAC address is
store in a pseduo-filesystem on Linux under `/sys`. Specifically, if you read
the entry `/sys/class/net/eth0/address`, you would be accessing the MAC address
of `eth0`.

{:.highlight}
Therefore, to run the code, you would do something like: `./ping.bin $(cat
/sys/class/net/eth0/address)`

If you implement this correctly, you should see something like (skip the
`./connect_*.sh` part if you are already on those machines):

  ```sh
  (netsec-01) $ ./connect_attacker.sh
  ┌──(root㉿attacker)-[/volumes/src/ping]
  └─# ./ping.bin $(cat /sys/class/net/eth0/address)
  [LOG:ping.c:main:75] ./ping.bin (27): Found device: eth0
  [LOG:ping.c:main:103] Running ping.bin with filter icmp and (not ip src 10.10.0.10) and (not ether src 02:42:0a:0a:00:0a)
  [LOG:parse_icmp.c:parse_icmp:44] Received ICMP Echo Request from 10.10.0.4

  ```
while from `hostA`:

  ```sh
  (netsec-01) $ ./conect_hostA.sh
  ┌──(root㉿hostA)-[/]
  └─# ping -c1 attacker
  PING attacker (10.10.0.10) 56(84) bytes of data.

  --- attacker ping statistics ---
  1 packets transmitted, 0 received, 100% packet loss, time 0ms
  ```

### Step 2: Send the reply

Now, we know that we have found our ICMP Echo Request, so we must send our
reply. The steps involved in doing that are following:

1. Create space of the new packet to be sent.
2. Set the content of the Ethernet header.
3. Set the content of the IPv4 header.
4. Set the content of the ICMP header.
5. Send the packet.

However, it is tedious to do all of that every single time. So we'll do a little
hack. Our ICMP Echo Reply looks exactly the same as the Echo Request, except for
some fields changed here and there, so we will first __copy__ the old packet
into the new one, edit it, and then send it.

Note that there's a reason why we carried the `len` field with us all this time.
We will need it to know how much memory to allocate.

So first, allocate room for the return packet and do some error checking:
  ```c
  retpkt = mallock(len);
  if(!retpkt) {
    print_err("PANIC: No more room in memory\n");
    exit(99);
  }
  ```

Next, copy the packet received into the newly created one:
  ```c
  memcpy(retpkt, pkt, len);
  ```

Now, let's start editing, it is useful to grab the headers, so let's just do
exactly that:
  ```c
  eth_hdr = (struct ether_header*)pkt;
  iphdr =     // TODO: Add code to get the IPv4 header IN THE NEW PACKET.
  reticmp =   // TODO: Add code to the ICMP header IN THE NEW PACKET.
  ```

First, let's start the Ethernet header. This is now going from attacker to
hostA, while the one we received came from hostA to attacker, so we'd need to
swap the MAC addresses. Note that we have our own MAC address in the `eth_addr`
structure at line 32.

Copy source host into destination host:
```c
memcpy(eth_hdr->ether_dhost, eth_hdr->ether_shost,
    sizeof eth_hdr->ether_shost);
```
Copy our MAC address into the source host:
```c
memcpy(eth_hdr->ether_shost, eth_addr->ether_addr_octet,
    sizeof eth_hdr->ether_shost);
```

Next, swap the source and destination IPv4 addresses, this is a bit easier since
we just swap out pointers rather than needing to copy memory:
```c
tmp_addr = iphdr->daddr;     // save destination address.
iphdr->daddr = iphdr->saddr; // set destination to source.
iphdr->saddr = tmp_addr;     // set source address to previous destination.
```

Finally, we need to adjust the ICMP header's `type` and `code` fields:
```c
reticmp->type = // TODO: set the appropriate type.
reticmp->code = // TODO: set the appropriate code.
```

Finally, send the packet and free the memory:
```c
pcap_inject(handle, retpkt, len);
free(retpkt);
```

Now, compile the code on the `netsec-01` server using `make`, then run it on the
attacker machine, and from hostA, try to ping the attacker. 

### Lab sheet questions

On your lab sheet, answer the following questions:

1. Was your `ping` successful? (Hint: it should not be!)
2. Grab a packet capture from `hostA` and examine it using `tshark` or
   `Wireshark`. You will see that your Reply packet was received by `hostA`, but
   it was dropped.

   Examine the packet and its headers, why did `hostA` drop the packet?

   _Hint_: Wireshark will highlight the problem for you, you can't miss it!

3. What is the use of the field that caused the problem?

### Step 3: Fixing the problem

Finally, let's fix the problem from step 2. First, read the RFC for the ICMP
headers [here](https://datatracker.ietf.org/doc/html/rfc792), specifically focus
on the description of each field.

To help you out, `util.h` contains a function called `chksum` that computes the
required value over a header, starting from the start of header. However, it
requires us to pass it the pointer as to pointer to two bytes, instead of a
pointer to a header.

For example, to use `chksum` over the `reticmp` structure from before, we would
do something like:
```c
chksum((uint16_t*)reticmp, len - sizeof *eth_hdr - sizeof *iphdr);
```

Note that we need to apply this function on all the bytes of the ICMP message,
include the random data at the end, which is why we use `len - sizeof *eth_hdr -
size *iphdr`.

Now, before you send the packet, recompute that field, set it in the ICMP
header, and then send the packet (make sure to do what the RFC above tells you
to do before the computation). Your code would look something like:
```c
// Do something from the RFC
reticmp->/*field name*/ = chksum((uint16_t*)reticmp, len - sizeof *eth_hdr - sizeof *iphdr);
```

{:.highlight}
Yes the name of the function in `util.h` tells you exactly what you are looking
for!

Finally, we need to do the same for the IPv4 header, you can reuse the same
process as above, only replace `reticmp` with `iphdr`. However, we only need to
do it over the header itself, not the rest of the protocols, so it would look
like:
```c
// do something similar to above from the RFC
iphdr->/*field name*/ = chksum((uint16_t*)iphdr, sizeof *iphdr);
```

Once that is done, recompile and test again, you should see something like the
following:
  ```sh
  ┌──(root㉿attacker)-[/volumes/src/ping]
  └─# ./ping.bin $(cat /sys/class/net/eth0/address)
  [LOG:ping.c:main:75] ./ping.bin (37): Found device: eth0
  [LOG:ping.c:main:103] Running ping.bin with filter icmp and (not ip src 10.10.0.10) and (not ether src 02:42:0a:0a:00:0a)
  ```
and from hostA
  ```sh
  ┌──(root㉿hostA)-[/]
  └─# ping -c2 attacker
  PING attacker (10.10.0.10) 56(84) bytes of data.
  64 bytes from attacker.local-net (10.10.0.10): icmp_seq=1 ttl=64 time=6.30 ms
  64 bytes from attacker.local-net (10.10.0.10): icmp_seq=2 ttl=64 time=4.62 ms

  --- attacker ping statistics ---
  2 packets transmitted, 2 received, 0% packet loss, time 1002ms
  rtt min/avg/max/mdev = 4.623/5.463/6.304/0.840 ms
  ```

# 2. Disconnecting the two hosts

# 3. Man in the Middle

