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

{:.highlight}
If you are enable to execute a script due to a permissions issue, then try the
following `$ chmod +x <script name.sh>` to make it executable and try again.

{:.warning}
In the remainder of this document, I will not be using your specific prefixes
and subnets. For example, when I refer to `hostA`, you should replace that with
`user-hostA` where `user` is your RHIT username. Similarly, I will be using
`10.10.0` as the default subnet, you should replace that in all IP addresses
with your own subnet. For example, if your subnet is `10.11.0`, then replace the
IP address `10.10.0.1` with `10.11.0.1`.

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
store in a pseudo-filesystem on Linux under `/sys`. Specifically, if you read
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

## Phase one: Understanding the ARP cache

We would like to first understand the behavior of the ARP cache at a host. We
will start with a simple experiment and packet capture.  Spin up your docker
environment using `docker compose up -d` then grab three terminals, two on
`hostA` and one on `hostB`.

First, let's check out the content of the ARP table on each container. Run the
following command on each host and check that the content of the ARP table are
empty.

  ```sh
  (hostA) $ arp -a -n
  ```

You should not see anything in the table on either host. If there is anything in
the table, you can flush it using `ip -s -s neigh flush all`.

Starting from an empty ARP table, let's first ping `hostA` from `hostB`, while
at the same time capturing traffic on `hostA`, as follows:

  ```sh
  (hostA) $ tcpdump -i eth0 arp or icmp -w /volumes/phaseone.pcap
  ```
and then from another terminal on `hostA`,
  ```sh
  (hostA) $ ping -c1 hostB
  ```

After the `ping` is successful, stop `tcpdump` and look at the packet capture.
For this to make sense, please do not let `tcpdump` run for long after the
`ping` stops, otherwise it will skew the results.

Check the content of the ARP cache on both `hostA` and `hostB` using `arp -a
-n`.

### Lab sheet questions

By examining the content of the ARP caches on `hostA` and `hostB`, and looking
at the packet capture, answer the following questions:

1. How many ARP request were sent from `hostA` to `hostB`?
2. What are the content of the caches on both `hostA` and `hostB`?
3. Based on your observation, what did `hostB` do when it received the ARP
   request from `hostA`?
4. Describe in a few sentence the steps taken by `hostB` when it received a
   request from `hostA` for its MAC address.
5. Based on your observations, assuming ARP caches are empty, what can a
   malicious host do to poison the ARP table of a host on the network?

## Phase two: Forging replies

Our goal now is to experiment with happens when a host on the network sends
unsolicited ARP replies for a fake IPv4 address that it doesn't own. Our first
goal for the attacker is to convince `hostA` that it is (i.e., the attacker)
`hostB`, by creating a fake mapping in `hostA`'s ARP cache that maps `hostB`'s
IPv4 to `attacker`'s MAC address. In simpler words, we would like to trick
`hostA` into thinking that `attacker` is `hostB`, so that it sends its traffic
there instead of the intended destination.

We would like to investigate the impact of sending forged ARP requests in two
cases:
  1. The ARP cache on our target (i.e., `hostA`) is empty.
  2. The ARP cache on our target (i.e., `hostA`) is already populated.

### Lab sheet questions

1. Describe the experiment that you would like to setup to evaluate the impact
   of forged ARP requests. Your experiment must be able to address the following 
   requirements:
   - Use appropriate packet captures to show the impact of ARP replies forged
     from the attacker to `hostA`.
   - Show the impact of the forged request on the ARP cache under different
     scenarios.
   - Analyze if and when the attack might be successful, and what happens if
     `hostB` starts communicating with `hostA` all of a sudden.

{:.highlight}
Once you have designed your experiment, please check in with your instructor
that your setup is able to address all the specifications above.

**HINT**:

ARP has a few implementation-specific behaviors that are not specified by the
RFC. To help us understand those behaviors better, here's a little experiment.
Grab a terminal window on `hostA` and make sure the ARP cache is empty (by
running `ip -s -s neigh flus all`).

Now try to ping a non-existing host on the network (with no attack running), and
then examine the content of the ARP cache using `arp -an`. You will see that
`hostA` will create an _incomplete_ entry for the unknown host, even if that
host did not reply to its requests.

```sh
┌──(root㉿hostA)-[/]
└─# arp -an
? (10.10.0.12) at <incomplete> on eth0
```

Using this observation, design your experiment so that you examine the behavior
of the ARP cache under these scenarios:

  1. The ARP cache is empty (for that specific IPv4 address).
  2. The ARP cache contains an incomplete mapping for the target IPv4 address.
  3. The ARP cache contains a valid mapping for the target IPv4 address.

### Sending forged requests

I have provided you with starter code to forge `ARP` replies, you can find it
under `lab2/volumes/src/phase_two` in the labs repository.

Add your code to the `send arp_replies` function at the top of the file. The
code assumes the following naming convention:

  - `target` is the machine you are trying to trick, i.e., the target of the ARP
    cache poisoning.
  - `victim` is the machine you are trying to impersonate, i.e., the one you are
    trying to create a fake mapping for.

### Success criteria

We consider our attack to be successful if we can convince `hostA` to send all
traffic intended to go to `hostB` to the attacker machine instead. To evaluate
that, we can do two things:

  - Check the content of the ARP cache at `hostA` during the attack using `arp
    -an`.
  - Attempt a `ping` from `hostB` to `hostA`, in that case, `hostB` should not
    receive any replies during the attack, since all packets are being sent to
    the `attacker` instead.

### Lab sheet questions

Based on your observations, answer the following questions on the lab questions
sheet.

  1. Based on your observations, describe the behavior of `hostA` when it
     receives an unsolicited ARP reply. Specifically, mention what happens
     depending on the content of the ARP cache.

  2. When would such an attack (using ARP replies) be successful?

  3. Based on your observations, suggest a way to thwart ARP cache poisoning
     attacks that use ARP replies.

  4. When the attack using ARP replies fails, can you suggest a way to remedy
     that? In other words, we'd still like to use ARP replies, but we need to
     force `hostA` to take those seriously.
     - _Hint_: You might need to send packets on another layer.
     - _Hint_: This is related to the incomplete mapping behavior that we have
       seen above.
     - You do not have to implement this, just suggest a way to make it happen.

## Phase three: Forging requests

Another approach to poisoning the cache at our target machine is to use
unsolicited ARP requests. We will now repeat the experiment from Phase two, but
instead use ARP requests.

I suggest you use your code from phase two and adjust the fields. Here's a quick
way to set yourself up, start from the directory `volumes/src/`

  ```sh
  (netsec-01:netsec-labs-user/lab2/volumes/src) $ mkdir phase_three
  (netsec-01:netsec-labs-user/lab2/volumes/src) $ cp phase_two/makefile phase_three/
  (netsec-01:netsec-labs-user/lab2/volumes/src) $ cp phase_two/send_reply.c phase_three/send_request.c
  ```

Then edit the file in `phase_three/send_request.c` to send requests instead of
replies. You do not need to edit the `makefile` as it detects your source files
automatically.

{:.warning}
Please do not put two files with `main` functions under the same directory,
otherwise the `makefile` would not be able to generate the executables and you
will get linking errors. Use separate directories if you need different
executables.

### Lab sheet questions

Based on your observations, answer the following questions on the lab questions
sheet.

  1. Based on your observations, describe the behavior of `hostA` when it
     receives an unsolicited ARP request. Specifically, mention what happens
     depending on the content of the ARP cache.

  2. When would such an attack (using ARP requests) be successful?

  3. If `hostB` decides to start sending ARP requests while you are conducting
     your attack, what do you anticipate would happen?
     - You do not have to test this out, just use your judgment as to what you
       think can happen.

## Phase four: ARP gratuitous

In the case both requests and replies do not work, ARP provides you with another
way to make announcements, specifically using _gratuitous ARP_ packets. A
gratuitous ARP packet is one that a host can send to announce itself on the
network (it has useful applications, though not without its drawbacks).

In this phase, we would like to experiment with gratuitous ARP packets to see if
they can help us impersonate `hostB`. We will use the same experimental setup as
in the first two phases, except that we will be sending gratuitous ARP packets.

I suggest you copy your code from **phase two** a new directory (call it
`phase_four`) and rename your file to `send_gratuitous.c`. It is better to start
from send replies since a gratuitous packet is slight modification of reply
packet.

An ARP gratuitous message is an ARP reply with the following characteristics:

  1. It is an ARP reply, i.e., its code should be the same as a reply packet.
  2. It is a broadcast packet, i.e., the target Ethernet address should be
     $$\mathtt{FF:FF:FF:FF:FF:FF}$$.
  3. The sender and target **IPv4** addresses should be the same; they would be
     the IPv4 address of the host we are trying to impersonate (i.e., `hostB`).
  4. The sender MAC address (in the ARP header) should be the MAC address of the
     attacker.
  5. The target MAC address of the ARP header should be the broadcast address
     (i.e., $$\mathtt{FF:FF:FF:FF:FF:FF}$$.

Repeat your experiment with gratuitous messages and record your observations.
Recall to clear the cache between experiments using `ip -s -s neigh flush all`.

### Lab sheet questions

Based on your observations, answer the following questions on the lab questions
sheet.

  1. Based on your observations, describe the behavior of `hostA` when it
     receives an unsolicited ARP request. Specifically, mention what happens
     depending on the content of the ARP cache.

  2. When would such an attack (using ARP gratuitous) be successful?

  3. Thinking like an attacker, which technique of the three would you prefer?
     Make sure to argue for your answer.

  4. Based on all your experiments, without significant change to the ARP
     protocol, can such attacks be thwarted?

     In your answer, try to hit the following points:
     - What is the main weakness of ARP?
     - Without a third party intervention, can this weakness be avoided?
     - Can someone from the Internet conduct an ARP cache poisoning attack?

# 3. Man in the Middle

Now, to make things interesting, we would like to use ARP cache poisoning to
conduct a man-in-the-middle attack on `hostA` and `hostB`. Our goal is to
intercept all the traffic going from `hostA` to `hostB`, and vice versa.

To achieve that, we must do the following:

  1. Attacker must trick `hostA` to map `hostB`'s IPv4 address to attacker's MAC
     address in its ARP cache.

  2. Attacker must trick `hostB` to map `hostA`'s IPv4 address to attacker's MAC
     address in its ARP cache.

  3. The attacker must make sure that the mappings are not dropped and replaced
     by the legitimate ones.

In this lab, we will intercept traffic between two `netcat` applications running
on `hostA` and `hostB`, and play a little prank. 

## Step 1: Exploring `netcat`

Let's first understand how `netcat` works so we can plan our attack accordingly.
Grab three terminal windows, two on `hostA` and one on `hostB`.

On `hostA` start a packet capture for all IP traffic.

  ```sh
  (hostA) $ tcpdump -i eth0 ip -w /volumes/netcat.pcap
  ```

Then start the server on either host, I will go with `hostA`:

  ```sh
  (hostA) $ nc -l 1234
  ```

On the other machine (`hostB` in my case), connect to the server:

  ```sh
  (hostB) $ nc hostA 1234
  ```

Now type a few words on `hostB` and press `<Enter>`, those same words will show
up on `hostA` where the `netcat` server is running. It is a simple way of
testing if two hosts can connect and exchange packet.

Stop the packet capture, download the pcap file, and open it in Wireshark. You
will notice that a new protocol shows up, namely TCP, which stands for
Transmission Control Protocol. We will explore TCP in depth later on, all we
care about now is to find where the words we have typed are.

### Lab sheet questions

By observing the pcap captures, locate the words you have typed during the
experiment in the captured packets. You will need to expand the TCP protocol
header to be able to see those and answer the following question:

  1. Grab a TCP packet, and open its corresponding IPv4 header. What is the
     value of the protocol number in the IPv4 header? Record this value in your
     notes.
  2. Which TCP packets contain the words that you have typed during the `netcat`
     experiment?
  3. For those packets containing the data, open their TCP header, what is the
     value of the **flags** field? Which flags are actually set? Record those
     flags.

## Step 2: Disconnecting the hosts

Now let's launch the attack. We would need to do it on two fronts, one that
poisons `hostA`'s cache, and another that poisons `hostB`'s cache. You can use
whichever technique you'd like.

First, create a directory called `exploit` under `volumes/src` and create a file
called `poison.c` in there. You can copy the code from the appropriate attack
type you created in the corresponding phase.

There are plenty of ways to do this, so I will leave it to you to design it. You
can use multiprocessing, multi-threading, or simply just have one loop generate
both attack packets at the same time. But here is the gist:

  - Every time, we'd like to generate two packets, one to poison `hostA`'s
    cache, and another to poison `hostB`'s cache.
  - Once you implement this, monitor the ARP caches on `hostA` and `hostB` to
    make sure you attack is successful (recall to use `arp -an` to check the
    content of the ARP cache).
  - If you make any assumptions about the prior status of the ARP cache, please
    do state those in your lab sheet. The less assumptions you make, the more
    successful your attack is going to be. You can start simply and then remove
    assumptions as you go on.

{:.warning}
If you are using a loop to send packets, please **do not flood the network** all
the time. Since the server is shared, we'd like to have a graceful status of the
network. In each iteration, inject a small sleep cycle to slow things down a
bit. This should not affect your exploit at all. To force your code to sleep for
a second, you can use `sleep(1);` and your code will sleep for a second.

### Success criteria

If your attack is successful, the hosts will no longer be able to talk to each
other. Make sure to test the following cases:

  1. ping from `hostA` to `hostB`, no packets should be delivered, but the
     packets should show up at the attacker. Use tcpdump to make sure they show
     up.
  2. ping from `hostB` to `hostA`, no packets should be delivered, but the
     packets should show up at the attacker. Use tcpdump to make sure they show
     up.
  3. repeat the `netcat` experiment, no connection should be established.

{:.highlight}
Once you are ready, please show me the outcome of your experiment to verify it
is successful. Once you get the green light, move on to step 3 below.

## Step 3: Pulling the prank

Our main goal here is to keep `hostA` and `hostB` communicating, but to observe
their packets and modify their content. To do so, we must sniff all packets that
are destined for either host, modify them, and then send them back out.

For our specific purposes, here's what we want to do:

  1. Listen for TCP packets coming from either `hostA` or `hostB`.

  2. If the packet does not contain `netcat` data (_Hint_: use the flags value
     you recorded in the `netcat` experiment), skip to step 4.

  3. If the packet contains `netcat` data (i.e., it contains messages), modify
     the content of those messages to our liking.

  4. Send the packet back on the wire (use `pcap_inject`).
 
Here's my breakdown of the approach (you don't have to stick to it):

  1. Create a directory under `volumes/src/`, call it `netcat`.

  2. Copy the `makefile` from the phase two into that directory.

  3. Create a new file, call it `netcat.c`.

    This file must sniff packets on the network, i.e., it not only sends
    packets, but also wants to capture them. You can use any one of the `print`
    files we used in the prelab as starter code, or just the `ping.c` program we
    created at the start of this lab.

  4. To make life easier, modify the `filter_expr` to only capture TCP packets
     and ignore everything else, this way you know for a fact that packets you
     receive are TCP and you don't need to do involved checks, `libpcap` will do
     that for you.

     Here's a suggested filter expression: `tcp and (ip src <IP of hostA> or ip
     src <IP of hostB>)`.

     This will only capture TCP packets generated from either `hostA` or
     `hostB`.

  5. Grab those packets, check their flags, modify those that need to be
     modified, and then send them back.

{:.warning}
Do not add characters to the TCP packet payload, TCP is very sensitive to
changes in the lengths of its packets, as we will discuss later in the class.
There will come a time where we'll have to deal with this annoyance, but it's
not today.

### Implementation tips

**Parsing TCP headers**

You would need to parse the TCP header for this task. You can use the `struct
tcpdhr` provided by the Linux kernel for this task. To use it, add this line to
the top of your file

```c
#include <linux/tcp.h>
```

Then, you can use it in the same way we did for all previous packet headers. For
example, given a packet pointer `pkt`, we could do:

```c
struct tcphdr *tcp = (struct tcphdr*)(pkt + sizeof(struct ether_header) + sizeof(struct iphdr));
```

Here are the content of that structure (vscode should help here as well):

```c
struct tcphdr {
  __be16  source;
  __be16  dest;
  __be32  seq;
  __be32  ack_seq;
#if defined(__LITTLE_ENDIAN_BITFIELD)
  __u16  res1:4,
    doff:4,
    fin:1,
    syn:1,
    rst:1,
    psh:1,
    ack:1,
    urg:1,
    ece:1,
    cwr:1;
#elif defined(__BIG_ENDIAN_BITFIELD)
  __u16  doff:4,
    res1:4,
    cwr:1,
    ece:1,
    urg:1,
    ack:1,
    psh:1,
    rst:1,
    syn:1,
    fin:1;
#else
#error  "Adjust your <asm/byteorder.h> defines"
#endif
  __be16  window;
  __sum16  check;
  __be16  urg_ptr;
};
```

The fact that flags are actually split into individual bits makes life a lot
easier. For example, if I want check if the header contains the `PUSH` and `SYN`
flags, I could simply do:

```c
if(tcp->syn && tcp->psh) {
  // found it.
}
```

Of course, you'd need to check for the flags you care about.

**Reaching the data**

If the packet contains data, then we need a way to access that data, and also
know how large it is. This will require us to peek a bit into the IPv4 header
and the TCP header. As we will see later in class, TCP headers can have varying
length options fields. This makes access the data a bit annoying. 

Luckily for us, the TCP header contains a field called the "data offset", which
tells us where the data starts, as an offset from the TCP header. Since by
design, the TCP header is always aligned to 32 bits (i.e., 4 bytes), this number
is reduce to 4 bits and represents the number of 4 byte words in the header.

For example, if the data offset is 4, then the header is actually $$4 \times 4$$
bytes long, which is 16 bytes.

Therefore, to calculate the start of our data segment, we'd do something like:

```c
// assume we created a struct tcphdr *tcp earlier...
char *data = (char*)tcp;
uint16_t tcp_hdr_len = tcp->doff * 4;
data = data + tcp_hdr_len;
```

Now, you can access the data of the TCP header. That is great, but how do I know
when to stop reading data? Now, we need the help of the IPv4 header. 

The IP header contains a 16-bit field called `tot_len` that represents the total
length of the packet include the IP header, the TCP header, and the data
(excluding the Ethernet header).

Therefore, we can calculate the data length as follows:

```c
uint16_t tot_len = ntohs(ip->tot_len);

// we are making an assumption here, but we'll let it go for now.
// talk to me if you'd like to really know what's going on.
uint16_t iphdr_len = sizeof(struct iphdr);
uint16_t tcp_hdr_len = tcp->doff * 4;

uint16_t data_len = tot_len - iphdr_len - tcp_hdr_len;

// the follow loop iterates over the data and replaces all a's with b's
char *data = (char*)tcp + tcp_hdr_len;
int i = 0;
for(; i < data_len; i++, data++) {
  if(*data == 'a') {
    *data = 'b';
  }
}
```

You might want to do something a bit better than just replacing a's with b's,
but you get the gist.

**Computing the checksum**

The last step we need to worry about is the checksum again (recall the ICMP
checksum from the first task in this lab). The TCP header also contains a
checksum field, but computing it a bit of a pain. It requires us to peek back
into the IP header and obtain a pseudo header from there. 

Here's the description from [RFC793](https://www.ietf.org/rfc/rfc793.txt):

    The checksum field is the 16 bit one's complement of the one's
    complement sum of all 16 bit words in the header and text.  If a
    segment contains an odd number of header and text octets to be
    checksummed, the last octet is padded on the right with zeros to
    form a 16 bit word for checksum purposes.  The pad is not
    transmitted as part of the segment.  While computing the checksum,
    the checksum field itself is replaced with zeros.

    The checksum also covers a 96 bit pseudo header conceptually
    prefixed to the TCP header.  This pseudo header contains the Source
    Address, the Destination Address, the Protocol, and TCP length.
    This gives the TCP protection against misrouted segments.  This
    information is carried in the Internet Protocol and is transferred
    across the TCP/Network interface in the arguments or results of
    calls by the TCP on the IP.

                     +--------+--------+--------+--------+
                     |           Source Address          |
                     +--------+--------+--------+--------+
                     |         Destination Address       |
                     +--------+--------+--------+--------+
                     |  zero  |  PTCL  |    TCP Length   |
                     +--------+--------+--------+--------+

    The TCP Length is the TCP header length plus the data length in
    octets (this is not an explicitly transmitted quantity, but is
    computed), and it does not count the 12 octets of the pseudo
    header.

To avoid dealing with this fugliness, I have provided you with a TCP header
checksum calculation routine, you can find that under the guides section of this
website. Feel free to port it directly into your code, or write your own if
bit mangling is what you're into.

### Success criteria

Your attack is successful if you can observe the following behavior (assuming
you decided to change all characters to `a`).

1. Starting a `netcat` on `hostA`, `hostB` can successfully connect to `hostA`.

2. All packets between `hostA` and `hostB` go through the attacker machine.

3. Packet not containing data pass through the attacker without modification.

4. Packets containing `netcat` data are all modified according to your own
   design (in our case, all characters are replaced with `a`).

5. If you type words on `hostB` and send them, they will show up as all `a`'s on
   `hostA`.

## Submission

Once your attack is working, submit your question sheet and code to Gradescope.


