---
layout: page
title: IP pcap tutorial
last_modified_date: Sun Dec 10 14:49:57 2023
current_term: Winter 2023-24
nav_order: 60
parent: Guides
description: >-
  IP packet parsing using libpcap.
---

## Table of contents
{:.no_toc}

1. TOC
{:toc}

---

# Introduction

This tutorial will walk you through how to parse and print an IPv4 header using
`libpcap`. It should serve as a follow up to the ARP printing task that we have
started in Prelab 2.

## Logistics

We will start off in the `prelab2` directory under the course repository.
Specifically, we will do most of our stuff in `prelab2/volumes/src/print`.

First, since we will be using the same packet capture setup as in the ARP
parsing task, let's just copy that code over. In the `print/` directory, copy
`printarp.c` into a new file, let's call it `printip.c`.

  ```sh
  $ cp printarp.c printip.c
  ```

Next, let's add `printip.c` as a target to the makefile in the same directory.
First, add the `printip.bin` to the `EXECUTABLES` variable at line 13.

  ```make
  EXECUTABLES := printpkt.bin printarp.bin printip.bin
  ```

Next, add the dependencies, right below the `printarp.bin: ...` rule (line 28).

  ```make
  printip.bin: $(OBJDIR)/printip.o $(LIBDIR)/libnslib.a
  ```

Now, if you compile everything using `make`, `printip.bin` will show up in the
directory. Right now, it does the exact same thing as `printarp` since it is an
exact copy. We will fix that next.

# Obtaining the IP packet

Let's check out the main loop (line 75), here it is for your convenience.

  ```c
    // MAIN LOOP: keep getting packets until error happens or we are done.
  while((rc = pcap_next_ex(handle, &hdr, &pkt)) >= 0) {
    // extract ethernet header and field
    eth_hdr = (struct ether_header *)pkt;
    eth_type_field = ntohs(eth_hdr->ether_type);

    // check if it's an ARP packet
    if(eth_type_field == ETHERTYPE_ARP) {
      parse_arp(pkt, hdr, handle);
    } else {
      print_log("(%s) Got a packet of len %d\n", fmt_ts(&hdr->ts), hdr->len);
    }
  }
  ```

Right now, we are only checking if the packet is an ARP packet, we need next to
check if it is an IP packet. So now, we will add a check to see if it's an IPv4
packet by looking at `eth_type`. You can check out the source code defining
the different constants for each protocol type
[here](https://elixir.bootlin.com/glibc/glibc-2.38/source/sysdeps/unix/sysv/linux/net/ethernet.h#L50).
But, here's the relevant part:

  ```c
  #define ETHERTYPE_IP       0x0800		/* IP */
  #define ETHERTYPE_ARP      0x0806		/* Address resolution */
  #define ETHERTYPE_REVARP   0x8035		/* Reverse ARP */
  #define ETHERTYPE_IPV6     0x86dd		/* IP protocol version 6 */
  #define ETHERTYPE_LOOPBACK 0x9000		/* used to test interfaces */
  ```

You are looking for IPv4, so we check `EHTERTYPE_IP` which has the value of
`0x0800`. These values are constant and are defined in the Ethernet standards,
you can find a bit more information about the Ethernet header
[here](https://wiki.wireshark.org/Ethernet).

So now, to catch IPv4 packet, we just need to handle those packets that match
the `ETHERTYPE_IP`. For now, we will just print that we received an IPv4 packet
and the timestamp at which we got it, something like the following:

  ```c
  else if(eth_type_field == ETHERTYPE_IP) {
    print_log("(%s) Got an IPv4 packet of length %d\n", fmt_ts(&hdr->ts), hdr->len);
  }
  ```

Let's simply test this one out. Compile the source code, then grab two
terminals, one on `attacker` and another on `hostA`. Run the code on `attacker`
(Note that the first line below simply shows you where you should be in the
directory tree).

  ```sh
  (attacker:/volumes/src/print)
  $ ./printip.bin
  ```

Then, from `hostA`, ping `attacker` with a single packet (note that we have
turned off pings, so you probably won't get a reply).

  ```sh
  (hostA:/)
  $ ping -c1 attacker
  ```

Here's the output I got, your would probably look different, but there should be
at least one IPv4 packet showing up.

  ```sh
  [LOG:printip.c:main:46] Starting printip.bin on interface eth0
  [LOG:printip.c:main:84] (20:22:04.282017) Got an IPv4 packet of length 98
  [LOG:../nslib/ns_arp.c:parse_arp:44] (20:22:09.535894) Who has 10.10.0.10? tell 10.10.0.4!
                  From 02:42:0a:0a:00:04 to 00:00:00:00:00:00.
  [LOG:../nslib/ns_arp.c:parse_arp:50] (20:22:09.535902) 10.10.0.10 is at 02:42:0a:0a:00:0a
  ```

# Printing IP header content

Let's now print the fields of the IPv4 packet, let's add a function for us to do
that, call it `parse_ipv4` so you can use it later on. Here's its signature:

  ```c
  void parse_ipv4(const u_char *pkt, pcap_pkthdr *hdr, pcap_t *handle);
  ```

Since we will need the IPv4 header structure, add the following to the top of
the file:

  ```c
  #include <netinet/ip.h>
  #include <netinet/in.h>
  ```

You can check out the source code
[here](https://elixir.bootlin.com/glibc/glibc-2.38/source/sysdeps/generic/netinet/ip.h),
and here's the packet header again for convenience.

  ```c
  struct iphdr
  {
#if __BYTE_ORDER == __LITTLE_ENDIAN
    unsigned int ihl:4;
    unsigned int version:4;
#elif __BYTE_ORDER == __BIG_ENDIAN
    unsigned int version:4;
    unsigned int ihl:4;
#else
# error  "Please fix <bits/endian.h>"
#endif
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

Also, here are the different constants for the IPv4 protocols:

  | Value | Constant       | Protocol |
  |-------|----------------|----------|
  | 1     | `IPPROTO_ICMP` | ICMP     |
  | 6     | `IPPROTO_TCP`  | TCP      |
  | 17    | `IPPROTO_UDP`  | UDP      |

Finally, to help you out with printing these things, here's a small helper
function to convert between them:

  ```c
  static const char *ip_proto_to_str(struct iphdr *ip) {
    switch(ip->protocol) {
      case IPPROTO_ICMP:
        return "ICMP";
        break;
      case IPPROTO_TCP:
        return "TCP";
        break;
      case IPPROTO_UDP:
        return "UDP";
        break;
      default:
        return "UNKNOWN";
    }
  }
  ```

First, we need to extract the header form the packet, so we should start reading
after the Ethernet header, so we must move into the packet by `sizeof(struct
ether_header)` bytes.

  ```c
  struct iphdr *ip = (struct iphdr *)(pkt + sizeof(struct ether_header));
  ```

That will simply move the packet pointer `pkt` by `sizeof(struct ether_header)`
bytes, and read those bytes as a `struct iphdr`.

Next, we can start printing things.

{:.warning}
Note that you must use `ntohs` and `ntohl` for reading anything that is larger
than a byte, otherwise, you will get incorrect results. No need to do anything
for values that are a byte or less.

Here's what my printing routine looks like:

  ```c
  void parse_ipv4(const u_char *pkt, struct pcap_pkthdr *hdr, pcap_t *handle) {
    struct iphdr *ip = (struct iphdr *)(pkt + sizeof(struct ether_header));
    print_log("(%s) Received an IPv4 packet:\n", fmt_ts(&hdr->ts));

    printf("+---------------------------------------------------------+\n");
    printf(" %-20s %-20s \n",   "Field",          "Value");
    printf(" %-20s %-20x \n",   "Version",        ip->version);
    printf(" %-20s 0x%-20x \n", "ID",             ntohs(ip->id));
    printf(" %-20s %-20u \n",   "TTL",            ip->ttl);
    printf(" %-20s %-20u \n",   "Protocol",       ip->protocol);
    printf(" %-20s %-20s \n",   "Parsed Prot",    ip_proto_to_str(ip));
    printf(" %-20s %-20s \n",   "Source IP",      ip_to_str(&ip->saddr));
    printf(" %-20s %-20s \n",   "Destination IP", ip_to_str(&ip->daddr));
    printf("+---------------------------------------------------------+\n");
  }
  ```

It simply prints some of the fields of the packet header, it is pretty
self-explanatory. Note that the `%-20s` syntax in the format specifier asks C to
do two things to what we print:
  1. Make sure what we print is at least 20 characters long, it append spaces if
     it is less.
  2. Make sure what we print is left-aligned.

It just allows for easy visual stuff, nothing much.

Finally, replace the print statement we added in the first part (for printing
the packet length) with a call to the function above (`parse_ipv4(pkt, hdr,
handle);`), and let's give it a try.

Using a similar setup (running `printip.bin` on the `attacker` and `ping` on
`hostA`), I got the following:

  ```sh
  (attacker:/volumes/src/print)
  $ ./printip.bin
  [LOG:printip.c:main:90] Starting printip.bin on interface eth0
  [LOG:printip.c:parse_ipv4:49] (21:11:17.865519) Received an IPv4 packet:
  +---------------------------------------------------------+
   Field                Value
   Version              4
   ID                   0x82e6
   TTL                  64
   Protocol             1
   Parsed Prot          ICMP
   Source IP            10.10.0.4
   Destination IP       10.10.0.10
  +---------------------------------------------------------+
  [LOG:printip.c:parse_ipv4:49] (21:11:18.879912) Received an IPv4 packet:
  +---------------------------------------------------------+
   Field                Value
   Version              4
   ID                   0x8334
   TTL                  64
   Protocol             1
   Parsed Prot          ICMP
   Source IP            10.10.0.4
   Destination IP       10.10.0.10
  +---------------------------------------------------------+
  [LOG:../nslib/ns_arp.c:parse_arp:44] (21:11:23.007903) Who has 10.10.0.10? tell 10.10.0.4!
                  From 02:42:0a:0a:00:04 to 00:00:00:00:00:00.
  [LOG:../nslib/ns_arp.c:parse_arp:50] (21:11:23.007909) 10.10.0.10 is at 02:42:0a:0a:00:0a
  ```

Experiment with this function a bit more and try some other fields. Then, when
you ready move on to the ICMP parsing exercise.


