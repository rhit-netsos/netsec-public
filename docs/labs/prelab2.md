---
layout: page
title: Prelab 2
last_modified_date: Wed Dec  6 22:35:50 2023
current_term: Winter 2023-24
nav_order: 20
parent: Labs
description: >-
  Setup and instructions for prelab 2.
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

A folder called `prelab2` should show up in your directory, that is where you
will do most of your lab.

## Patching the docker file

{.warning}
Before starting here, please make sure that your experiments from lab1 are down.
To do so, navigate back to the `lab1` directory and do `docker compose down`.

I have updated the patch script to no longer ask you for your username and
subnet, it will try to extract those on its own and print out your subnet (it is
the same on as the one announced on the Moodle page).

To do so, in the `prelab2` directory, run the patch script:

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

They all exist on the same local network and can talk to each other freely. Our
target at the end of this lab is to make the `attacker` container sit in the
middle of `hostA` and `hostB`, such that any packet from A to B or B to A, will
be intercepted by the attacker; this is referred to as a _Man in the Middle
Attack_ (MITM).

{:.highlight}
Please note that the `attacker` container is configured to ignore ICMP Echo
request packets, and thus will not respond to `ping` requests.

---

# libpcap tutorial

As you might have noticed in the previous lab, running our exploit using
`python` is very slow. On average, to get a response from a container on the
same (virtual) network, it took us an average of 35.435 ms; that is terrible, it
is even slower than me trying to access `8.8.8.8` (average of 15 ms). It will
also raise alarms in case traffic is this slow on a local network, thus
compromising an attacker's ability to hide their tracks.

We would like to do better in this lab, especially that we will start running
into cases where a successful exploit is performance-dependent. Therefore, we
will use C as our programming language, and make use of `libpcap` (same thing
provided by `tcpdump`) to write our exploit. This section serves as an
introduction and tutorial for `libpcap` in C.

{:.highlight}
`libpcap` is not the fastest either, but it is much faster than python. If we
really want things to run at line speed (i.e., as if there was an actual ghost
machine there), it would require a bit more hacking that is beyond what we will
cover in this class. If you are interested, take a look at
[`eBPF`](https://ebpf.io/) and
[`AF_XDP`](https://www.kernel.org/doc/html/next/networking/af_xdp.html).

### Sample comparison

When running the previous lab's exploit using C we get:

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

While when running it using `python` we get:

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

You can clearly see how big the difference is.

## Directory structure

Under the `prelab2/volumes` directory, you will see a `src/` directory that
contains the demo source code in addition to a bunch of utility helpers that
will be useful for you later on.

As of writing this document, my directory tree looks like the following:

  ```sh
  $ tree .
  .
  ├── nslib
  │   ├── log.h
  │   ├── ns_arp.c
  │   ├── ns_arp.h
  │   ├── util.c
  │   └── util.h
  └── print
      ├── makefile
      ├── printarp.c
      └── printpkt.c
  ```

The directories we care about are the following:

1. `nslib`: This contains a bunch of utilities and helper functions that you can
   use when writing your code. Feel free to use any function from this library.
   I tried to document everything to be self-explanatory of what each function
   is trying to do.
2. `print`: This contains the printing demos that we will look into, along with
   their corresponding `makefile`.
   - `printpkt.c`: This is a demo file that just prints when a packet is received
     with `libpcap`.
   - `printarp.c`: This is a demo file that prints the content of an ARP packet.

Of particular interest for us at this point is the `nslib/log.h` header file. It
contains a bunch macros that you can use to color your screen output to make
things more obvious. It provides three macros __that can be used exactly as you
would use `printf`__.

1. `print_log`: Prints the output in green color. It prepends the file name, the
   function name, and the line of code to the output.
2. `print_err`: Prints the output in red color with an `ERROR` label.
3. `print_warn`: Prints the output in yellow color with a `WARNING` label.

Feel free to use these functions to your desire, you just need `#include
"log.h"` in your list of headers included.

## Makefiles

I provide you with a template `makefile` that resolve all dependencies in each
directory. If you add new C files that you wish to compile, there are only two
lines that you need to edit; those are marked with `TODO:` in the `makefile`,
please do not edit any other rule in the file.

{:.warning}
If you are having issues with `make`, then don't spend time on it, that is not
the purpose of this class. Ask me about it and I will help you figure it out.

## Sniffing and printing packets

We will first start by looking at `print/printpkt.c`. This is a simple sniffer
that listens on the network for incoming packets, and then simply prints the
timestamp of when the packet was received, along with the packet's length in
bytes.

The code is well documented, but here are the highlights:

1. Fist, we'd like to find a device we listen on. By default, we listen on
   `eth0` (configured by the `ifname` variable in the code). Lines  36 through
   46 loop through all of the container's interfaces to find `eth0`, and return
   an error if they can't find it. You will rarely, if never, have to mess with
   this piece of code.
2. Second, we open the interface `eth0` for listening. We use the
   `pcap_open_live` function on line 49. This line will rarely change, and will
   write an error message into `errbuf` if it fails.

   However, of particular interest to us is the `PCAP_OPENFLAG_PROMISCUOUS` flag
   (the fourth argument). This will indicate that our interface should capture
   all packets, even those intended for other machines or non-existing machines.
   That is crucial for us to be able to run our exploit.
3. Third, we'd like to compile our packet filter. We only care about a certain
   subset of packets and not everything. In this demo, we only care about
   capturing ARP and ICMP packets. Lines 64 through 76 do just that.

   Of particular interest to us is the filter expression itself. It is defined
   at the top of the file in:
   ```c
   static const char *filter_expr = "arp or icmp";
   ```
   If you'd like to change that expression, you can either (1) change the
   variable directly, or (2) pass the filter expression as an argument to the
   program when you run it. For example to capture all IPv4 and ARP packets,
   we'd do
   ```sh
   ./printpkt.bin "ip or arp"
   ```
   Note that for expressions with spaces, you need to use the quotes.

4. Finally, our main loop lives on line 79, it is the following:

    ```c
    // MAIN LOOP: keep getting packets until error happens or we are done.
    while((rc = pcap_next_ex(handle, &hdr, &pkt)) >= 0) {
      // Eventually, remove this for speed
      tstr = fmt_ts(&hdr->ts);
      print_log("(%s)\t Got a packet of len %d\n", tstr, hdr->len);
    }
    ```

    This loop will continue listening for packets until it receives an error, or
    you exit the program. For every captured packet, it will execute the body of
    the loop. We will talk more about this loop in the next section.

### The sniffing loop

Our loop touches on the three following variables:
1. `pcap_t *handle`: This is a pointer to a `pcap_t` structure. It is returned
   to us by the `pcap_open_live` function. It contains metadata and config
   options for our sniffing session. You will never need to edit anything with
   this, you just need to pass it around sometimes to do `pcap` specific things.
2. `struct pcap_pkthdr *hdr`: This is a pointer to a `struct pcap_pkthdr`
   structure.

   This structure contains the following members:
    1. `ts`: a `struct timeval` representing the time when the packet got
       captured.
    2. `caplen`: the number of bytes that are available from the packet.
    3. `len`: the length of the packets, in bytes. This might be larger than
       `caplen` if the packet is bigger than what `libpcap` can handle.

3. `const u_char *pkt`: This will be a pointer to the actual bytes in the
   packet, we will be mostly working with this one.

In this loop, we are doing two things:

1. First, we use the utility function `fmt_ts` to read the packet's timestamp
   and format it into a nice string. You can check out the code for `fmt_ts` in
   `nslib/util.c`. Feel free to use this function as you see fit.
2. Then, we just print the formatted timestamp along with the length of the
   packet in bytes.

### Trying it out

Let's go ahead and try it out. First, compile the code from the `src/print`
directory:

  ```sh
  (netsec-labs-user/prelab2/volumes/src/print) $ make
  cc -MT build/printpkt.o -MMD -MP -MF build/.deps/printpkt.d -Werror -Wextra -I../nslib -ggdb   -c -o build/printpkt.o printpkt.c
  cc -MT lib/ns_arp.o -MMD -MP -MF build/.deps/ns_arp.d -Werror -Wextra -I../nslib -ggdb   -c -o lib/ns_arp.o ../nslib/ns_arp.c
  cc -MT lib/util.o -MMD -MP -MF build/.deps/util.d -Werror -Wextra -I../nslib -ggdb   -c -o lib/util.o ../nslib/util.c
  ar rcs lib/libnslib.a lib/ns_arp.o lib/util.o
  cc -Llib build/printpkt.o lib/libnslib.a -o printpkt.bin -lpcap -lnslib
  cc -MT build/printarp.o -MMD -MP -MF build/.deps/printarp.d -Werror -Wextra -I../nslib -ggdb   -c -o build/printarp.o printarp.c
  cc -Llib build/printarp.o lib/libnslib.a -o printarp.bin -lpcap -lnslib
  ```

Then, bring up the experiment from the `prelab2` directory:
  ```sh
  (netsec-labs-user/prelab2/) $ docker compose up -d
  ```

Then, login to the `attacker` container, and start the program.
  ```sh
  (attacker) $ cd /volumes/src/print/
  (attacker) $ ./printpkt.bin
  ```
  <div class="code-example" markdown="1">
  ```txt
  [WARNING:printpkt.c:main:31] Using default filter expression: arp or icmp
	[LOG:printpkt.c:main:33] Starting setup...
	[LOG:printpkt.c:main:48] Starting printpkt.bin on interface eth0
	[LOG:printpkt.c:main:76] Setup done successfully, listening for packets...
  ```
  </div>

Then, from `hostA`, try to ping the `attacker` container. Note that as we
mentioned above, that container does not respond to ICMP pings, so you will not
receive a reply.

  ```sh
  (hostA) $ ping -c1 attacker
  ```
  <div class="code-example" markdown="1">
  ```txt
  PING attacker (10.10.0.10) 56(84) bytes of data.

  --- attacker ping statistics ---
  1 packets transmitted, 0 received, 100% packet loss, time 0ms
  ```
  </div>

Once the `ping` had started, we see some packets at the `attacker`, looking like
the following:

  ```sh
  [LOG:printpkt.c:main:82] (17:13:55.009973)       Got a packet of len 42
  [LOG:printpkt.c:main:82] (17:13:55.009991)       Got a packet of len 42
  [LOG:printpkt.c:main:82] (17:13:55.010014)       Got a packet of len 98
  ```

## Printing ARP Requests

Now, let's make it more useful, we'd like to print the content of the packet we
receive. We will now be looking into `printarp.c`.

Recall from lab 1, that an ARP packets sits on top of the underlying physical
(data link) layer, which is Ethernet in our case. So our packet would look
something like this:

  ```
  + ------------------------------------------------ +
  +               ETHERNET HEADER                    +
  + ------------------------------------------------ +
  +                 ARP HEADER                       +
  + ------------------------------------------------ +
  ```

So we must peel those layers one by one to extract the information we care
about.

### Extracting the Ethernet header

First, let's peel off the Ethernet header. To do this, we will use a nifty C
trick, which is pointer casting. The main idea behind this is the following, the
packet is nothing but a bunch of bytes, so I will case different parts of the
packets into different pointers, thus allowing me to access the packet bytes in
a more readable way.

To represent an Ethernet header, we use the `struct ether_header` structure. You
can find the definition of that structure below:

  ```c
  struct ether_header
  {
  uint8_t  ether_dhost[ETH_ALEN];	/* destination eth addr	*/
  uint8_t  ether_shost[ETH_ALEN];	/* source ether addr	*/
  uint16_t ether_type;		        /* packet type ID field	*/
  } __attribute__ ((__packed__));
  ```

The header simply contains the destination mac address (as 6 bytes or 48 its),
the source mac address, and then the type of the protocol coming after that
header.

Therefore, all we need to do is to cast the packet into a pointer to a `struct
ether_header`, and we can access those fields easily, as follows:
`eth_hdr->ether_type`. You can check the source code of this structure by
following the link
[here](https://elixir.bootlin.com/glibc/latest/source/sysdeps/unix/sysv/linux/net/ethernet.h#L39).

{:.highlight}
Use the elixir link above to find the source code and documentation of any of
the headers and address structures we use in this class; it is very useful.

Now, we would need to check if the packet is an ARP packet, or something else.
Therefore, we can read the `ether_type` field. However, we have an issue here.

{:.warning}
Network packets are always in Big Endian order. This becomes a problem if our
machines are Little Endian, which would lead us to see incorrect values.
Therefore, anytime you are accessing anything that is larger than a byte in this
class, use `ntohs`, `ntohl`, `htons`, or `htonl` as you see fit.

We will need to `ntohs` to get the type field in the correct order that we can
read. Here are the common function you would use:
1. `ntohs`: Network to host order short. `short` stands for 16 bits, or 2 bytes.
2. `ntohl`: Network to host order long. `long` stands for 32 bits, or 4 bytes.
3. `htons`: Host to network order short.
3. `htonl`: Host to network order long.

So now, we can check the value of the field we extracted and compare it to the
ARP type we are looking for. Luckily, all those constants have been defined for
us, you can check them out at the same link above, but here they are for quick
reference:

  ```c
  /* Ethernet protocol ID's */
	#define	ETHERTYPE_IP		0x0800		/* IP */
  #define	ETHERTYPE_ARP		0x0806		/* Address resolution */
  ```

If the type field matches `ETHERTYPE_ARP` then we will call the function
`parse_arp` provided in `nslib/ns_arp.c`. Otherwise, we just print the same
thing we did in the previous exercise.

### Parsing the ARP header

Now, let's check out `parse_arp` function; it pretty much operates in the same
way that Ethernet parsing works, we are just dealing with a different protocol
header.

```c
int parse_arp(const u_char *pkt, struct pcap_pkthdr *hdr, pcap_t *handle) {
  static char logfmt[1024];
  char *str = logfmt;
  struct ether_header *eth;
  struct ether_arp *arp;
  struct in_addr *addr;
  struct ether_addr *eth_addr;
  u_short a_op;
  const char *ip, *mac;

  // grab the Ethernet header
  eth = (struct ether_header*)pkt;
  arp = (struct ether_arp*)(pkt + sizeof *eth);
  a_op = ntohs(arp->ea_hdr.ar_op);

  if(a_op == ARPOP_REQUEST) {
    // The ARP request has the following meaningful fields:
    //  - spa: Source physical address.
    //  - sha: Source hardware address.
    //  - tpa: Target physical address.
    //  - tha: Target hardware address.
    addr = (struct in_addr*)arp->arp_tpa;
    ip = inet_ntoa(*addr);
    str += sprintf(str, "Who has %s? ", ip);

    addr = (struct in_addr*)arp->arp_spa;
    ip = inet_ntoa(*addr);
    str += sprintf(str, "tell %s!\n", ip);

    eth_addr = (struct ether_addr*)arp->arp_sha;
    mac = ether_ntoa(eth_addr);
    str += sprintf(str, "\t\tFrom %s ", mac);

    eth_addr = (struct ether_addr*)arp->arp_tha;
    mac = ether_ntoa(eth_addr);
    str += sprintf(str, "to %s.", mac);

    print_log("(%s) %s\n", fmt_ts(&hdr->ts), logfmt);
    return 0;
  } else if (a_op == ARPOP_REPLY) {
    eth_addr = (struct ether_addr*)arp->arp_sha;
    addr = (struct in_addr*)arp->arp_spa;

    ip = inet_ntoa(*addr);
    mac = ether_ntoa(eth_addr);

    print_log("(%s) %s is at %s\n", fmt_ts(&hdr->ts), ip, mac);
    return 0;
  }
}
```

The first thing we notice is that we are now using `struct ether_arp` structure.
Here's the source code for that structure:

```c
struct	ether_arp {
	struct	arphdr ea_hdr;     /* fixed-size header */
	uint8_t arp_sha[ETH_ALEN]; /* sender hardware address */
	uint8_t arp_spa[4];        /* sender protocol address */
	uint8_t arp_tha[ETH_ALEN]; /* target hardware address */
	uint8_t arp_tpa[4];        /* target protocol address */
};
```

and for the inner structure, the source code is here:

```c
struct arphdr {
  unsigned short int ar_hrd;		/* Format of hardware address.  */
  unsigned short int ar_pro;		/* Format of protocol address.  */
  unsigned char ar_hln;		      /* Length of hardware address.  */
  unsigned char ar_pln;		      /* Length of protocol address.  */
  unsigned short int ar_op;		  /* ARP opcode (command).  */
};
```

Assuming we have a pointer to the ARP header called `arp`, here are the members
we care about:

1. `arp->ea_hdr.ar_op`: This is the operation that the ARP packet is doing,
   telling us whether it's ARP request, ARP reply, or any other parts of the ARP
   protocol.
2. `arp->arp_sha`: This is the packet sender's MAC address.
3. `arp->arp_spa`: This is the packet sender's IPv4 address (in this class).
4. `arp->arp_tha`: This is the packet target's MAC address.
5. `arp->arp_tpa`: This is the packet target's IPv4 address.

We can now start the parsing. We know that the ARP header is on top of the
Ethernet header, so we simply need to move the packet points by the size of an
Ethernet header to be able to access the ARP header.
This is exactly what the following line of code is doing:
  ```c
  arp = (struct ether_arp*)(pkt + sizeof *eth);
  ```
You can also write this one alternatively as:
  ```c
  arp = (struct ether_arp*)(pkt + sizeof(struct ether_header));
  ```

Now, we can parse the fields, but be aware that we will face the issue with
network byte order, so we must use the appropriate functions to handle it.
The line below achieves that:
  ```c
  u_short a_op = ntohs(arp->ea_hdr.ar_op);
  ```

Now we can check that against `ARPOP_REQUEST` and `ARPOP_REPLY` to see if the
packet contains a request or a reply.

### Formatting addresses

To help you out with printing, I have provided you with two utility functions:

1. `mac_to_str`: Takes a MAC address bytes and returns that address as a
   formatted string.

2. `ip_to_str`: Takes in an IP address bytes and returns that address as a
   formatted string.

{:.warning}
Both functions above return a static buffer, which means that it will be reused
by the next call to `ip_to_str`, thus overwriting whatever value was in there.
If you need a value to persist, then you need to manually copy the return value
into a separate buffer.

The rest of the code in `parse_arp` is just using those functions to print the
content of the packet in a nice format.

### Running the code

Compile the code using `make` in the `print` directory, and then run it on the
`attacker` container. Here is a sample output when `hostA` tries to ping the
`attacker` machine.

```sh
(attacker) $ ./printarp.bin
```
<div class="code-example" markdown="1">
[LOG:printarp.c:main:46] Starting printarp.bin on interface eth0
[LOG:printarp.c:main:84] (18:30:52.651590) Got a packet of len 98
[LOG:printarp.c:main:84] (18:30:53.663912) Got a packet of len 98
[LOG:printarp.c:main:84] (18:30:54.687916) Got a packet of len 98
[LOG:printarp.c:main:84] (18:30:55.711908) Got a packet of len 98
[LOG:printarp.c:main:84] (18:30:56.735902) Got a packet of len 98
[LOG:../nslib/ns_arp.c:parse_arp:44] (18:30:57.663900) Who has 10.10.0.10? tell 10.10.0.4!
                From 02:42:0a:0a:00:04 to 00:00:00:00:00:00.
[LOG:../nslib/ns_arp.c:parse_arp:50] (18:30:57.663907) 10.10.0.10 is at 02:42:0a:0a:00:0a
[LOG:printarp.c:main:84] (18:30:57.759906) Got a packet of len 98
[LOG:printarp.c:main:84] (18:30:58.783905) Got a packet of len 98
[LOG:printarp.c:main:84] (18:30:59.807900) Got a packet of len 98
[LOG:printarp.c:main:84] (18:31:00.831909) Got a packet of len 98
[LOG:printarp.c:main:84] (18:31:01.855903) Got a packet of len 98
</div>

# Task 1: Print an IP packet content

In this first task, create a program called `printip.c` that prints the content
of an IPv4 packet, if one is detected. Model your code after the `parse_arp`
function show in this tutorial.

For parsing the header, use the `struct iphdr` structure. You can find its
definition here (cleaned up a bit for clarity):

```c
struct iphdr {
    unsigned int ihl:4;
    unsigned int version:4;
    uint8_t tos;
    uint16_t tot_len;
    uint16_t id;
    uint16_t frag_off;
    uint8_t ttl;
    uint8_t protocol;
    uint16_t check;
    uint32_t saddr;
    uint32_t daddr;
    /*The options start here. */
  };
```

Don't forget to add the needed header files to access this structure:

```c
#include <netinet/ip.h>
```

To parse the IP header, first check if the Ethernet header contains an IPv4
header. If it does, the follow the say process we did with ARP:

```c
struct iphdr *ip = (struct iphdr*)(pkt + sizeof *eth_hdr);
```

To format and print an IPv4 address, you can use the same `ip_to_str` function
as follows:

```c
char *ip_str = ip_to_str((void*)&ip->saddr);
```

# Task 2: Print an ICMP packet content

In this second task, create a program called `printicmp.c` that prints the
content of an ICMP header, if one is found. The ICMP header structure looks as
follows:

```c
struct icmphdr
{
  uint8_t type;		/* message type */
  uint8_t code;		/* type sub-code */
  uint16_t checksum;
  union
  {
    struct
    {
      uint16_t	id;
      uint16_t	sequence;
    } echo;			/* echo datagram */
    uint32_t	gateway;	/* gateway address */
    struct
    {
      uint16_t	__glibc_reserved;
      uint16_t	mtu;
    } frag;			/* path mtu discovery */
  } un;
};
```

You can ignore the `union` for now, it simply represents the next 4 bytes of
content in the packet. You can for now just print the `type` and `code` in human
readable format, and then print the `checksum` in hex.

Don't forget to add the needed header files to access this structure:

```c
#include <netinet/ip_icmp.h>
```

# Submission

Submit your code to Gradescope.

