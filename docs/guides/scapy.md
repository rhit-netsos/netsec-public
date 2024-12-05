---
layout: page
title: scapy tutorial
last_modified_date: Wed 29 Nov 2023 04:42:25 PM EST
current_term: Winter 2023-24
nav_order: 50
parent: Guides
description: >-
  Brief scapy tutorial on sniffing and forging packets.
---

## Table of contents
{:.no_toc}

1. TOC
{:toc}

---

# Introduction

This tutorial serves as brief introduction to use `scapy` to sniff and forge
packets inside of a `python` script. Everything has already been set up on the
containers to be able to run `scapy` without any additional configuration.

In what follows, we assume a topology similar to that in [lab
1]({{site.baseurl}}/docs/labs/lab1), where we have three machines: `hostA`,
`hostB` and `attacker`.

{:.warning}
Recall to always replace the IPv4 addresses and hostnames here with those unique
to your experiment and your subnet.

## Sniffing packets

First, we will use `scapy` to sniff packets on the `attacker` machine.

  ```sh
  (attacker) $ ipython3
  Python 3.11.5 (main, Aug 29 2023, 15:31:31) [GCC 13.2.0]
  Type 'copyright', 'credits' or 'license' for more information
  IPython 8.14.0 -- An enhanced Interactive Python. Type '?' for help.

  In [1]: from scapy.all import *

  In [2]: pkt=sniff(iface='eth0', filter='arp or icmp')
  ```
This will sit there waiting for packets to arrive on the `eth0` interface.

Let's generate some traffic from `hostA` to the `attacker` machine, as follows:
  ```sh
  (hostA) $ ping -c1 attacker
  PING attacker (10.10.0.13) 56(84) bytes of data.
  64 bytes from attacker.local-net (10.10.0.13): icmp_seq=1 ttl=64 time=0.086 ms

  --- attacker ping statistics ---
  1 packets transmitted, 1 received, 0% packet loss, time 0ms
  rtt min/avg/max/mdev = 0.086/0.086/0.086/0.000 ms
  ```

Now, go back to the `attacker` machine, and hit `C-c` to break out of the
sniffing task. Then use `pkt.show()` to list all the packets that the sniffer
was able to receive. In my case, it looked something like the following:
  ```sh
  In [3]: pkt.show()
  0000 Ether / IP / ICMP 10.10.0.4 > 10.10.0.13 echo-request 0 / Raw
  0001 Ether / IP / ICMP 10.10.0.13 > 10.10.0.4 echo-reply 0 / Raw
  0002 Ether / ARP who has 10.10.0.4 says 10.10.0.13
  0003 Ether / ARP who has 10.10.0.13 says 10.10.0.4
  0004 Ether / ARP is at 02:42:0a:0a:00:0d says 10.10.0.13
  0005 Ether / ARP is at 02:42:0a:0a:00:04 says 10.10.0.4
  ```
{:.highlight}
Your output might look different depending on the state of the container at
the time, but you should at least see the ICMP echo-request and echo-reply
packets.

`pkt` is nothing but an array of packets. To examine one of those packets, you
can access it individually by indexing into `pkt`. For example, to check out the
first `echo-request` packet above, you would do:

  ```sh
  In [4]: pkt[0].show()
  ###[ Ethernet ]###
    dst       = 02:42:0a:0a:00:0d
    src       = 02:42:0a:0a:00:04
    type      = IPv4
  ###[ IP ]###
       version   = 4
       ihl       = 5
       tos       = 0x0
       len       = 84
       id        = 57926
       flags     = DF
       frag      = 0
       ttl       = 64
       proto     = icmp
       chksum    = 0x443e
       src       = 10.10.0.4
       dst       = 10.10.0.13
       \options   \
###[ ICMP ]###
          type      = echo-request
          code      = 0
          chksum    = 0xac1e
          id        = 0x52
          seq       = 0x1
          unused    = ''
###[ Raw ]###
             load      = '\\xea2he\x00\x00\x00\x00.#\x0c\x00\x00\x00\x00\x00\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f !"#$%&\'()*+,-./01234567'
  ```

You can also view more detailed information about the packet using `ls(pkt[0])`
as follows:

```sh
In [5]: ls(pkt[0])
dst        : DestMACField                        = '02:42:0a:0a:00:0d' ('None')
src        : SourceMACField                      = '02:42:0a:0a:00:04' ('None')
type       : XShortEnumField                     = 2048            ('36864')
--
version    : BitField  (4 bits)                  = 4               ('4')
ihl        : BitField  (4 bits)                  = 5               ('None')
tos        : XByteField                          = 0               ('0')
len        : ShortField                          = 84              ('None')
id         : ShortField                          = 57926           ('1')
flags      : FlagsField                          = <Flag 2 (DF)>   ('<Flag 0 ()>')
frag       : BitField  (13 bits)                 = 0               ('0')
ttl        : ByteField                           = 64              ('64')
proto      : ByteEnumField                       = 1               ('0')
chksum     : XShortField                         = 17470           ('None')
src        : SourceIPField                       = '10.10.0.4'     ('None')
dst        : DestIPField                         = '10.10.0.13'    ('None')
options    : PacketListField                     = []              ('[]')
--
type       : ByteEnumField                       = 8               ('8')
code       : MultiEnumField (Depends on 8)       = 0               ('0')
chksum     : XShortField                         = 44062           ('None')
id         : XShortField (Cond)                  = 82              ('0')
seq        : XShortField (Cond)                  = 1               ('0')
ts_ori     : ICMPTimeStampField (Cond)           = None            ('25089089')
ts_rx      : ICMPTimeStampField (Cond)           = None            ('25089089')
ts_tx      : ICMPTimeStampField (Cond)           = None            ('25089089')
gw         : IPField (Cond)                      = None            ("'0.0.0.0'")
ptr        : ByteField (Cond)                    = None            ('0')
reserved   : ByteField (Cond)                    = None            ('0')
length     : ByteField (Cond)                    = None            ('0')
addr_mask  : IPField (Cond)                      = None            ("'0.0.0.0'")
nexthopmtu : ShortField (Cond)                   = None            ('0')
unused     : MultipleTypeField (ShortField, IntField, StrFixedLenField) = b''             ("b''")
--
load       : StrField                            = b'\xea2he\x00\x00\x00\x00.#\x0c\x00\x00\x00\x00\x00\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f !"#$%&\'()*+,-./01234567' ("b''")
```

## Sniffing in a script

You do not want to these things from `ipython3`, it is not very practical for
our purposes. You can actually put the above in a script that will handle each
packet received separately using a _callback_ function.

Here's what it would look like (assume file name is `sniff.py`):

```python
#!/usr/bin/env python3
from scapy.all import *

def print_pkt(pkt):
  pkt.show()

if __name__ == '__main__':
  pkt = sniff(iface='eth0', filter='arp or icmp', prn=print_pkt)
```

The above script will start sniffing on `eth0` while filtering for only `arp`
and `icmp` packets (i.e., it will ignore all others). `prn=print_pkt` sets the
callback function to be `print_pkt` which will be called every time a packet is
received (you can kind of see why `scapy` and `python` are slow!)

To run this script, first adjust its access bit using:
  ```sh
  $ chmod +x sniff.py
  ```
Then, run it using:
  ```sh
  ./sniff.py
  ```

## Crafting packets

Now that we know how to sniff packets, let's craft some; it's pretty easy (but
slow) in `scapy`. Let's create a script called `gen_ping.py` as follows:

```python
#!/usr/bin/env python3
from scapy.all import *
from scapy.layers.inet import IP, ICMP

# generate an IP header
iphdr = IP()

# set the destination, let's talk to hostA
iphdr.dst = '10.10.0.4'

# generate an icmp header, by default, scapy generates an echo-request packet
icmphdr = ICMP()

# concatenate the two headers
pkt = iphdr/icmphdr

# if we're just interested in sending the packet, we can use:
# send(pkt)

# However, we want to expect a response, so we use:
reply = sr1(pkt)

# the above will block until a reply packet is received.
print("Got a response packet:")
reply.show()
```

The comments above should be self-explanatory, it is as simple as that! Recall
that if you'd like to view the fields of a packet and check what you can edit,
you can always use `ls(pkt)`.

{:.warning}
Make sure you change the IPv4 address in the line `iphdr.dst = '10.10.0.4'` to
the address of `hostA` that works for your experiment.

Running this script on the `attacker` machine would look like the following:
```sh
(attacker) $ chmod +x gen_ping.py
(attacker) $ ./gen_ping.py
Begin emission:
Finished sending 1 packets.
.*
Received 2 packets, got 1 answers, remaining 0 packets
Got a response packet:
###[ IP ]###
  version   = 4
  ihl       = 5
  tos       = 0x0
  len       = 28
  id        = 54273
  flags     =
  frag      = 0
  ttl       = 64
  proto     = icmp
  chksum    = 0x92bb
  src       = 10.10.0.4
  dst       = 10.10.0.13
  \options   \
###[ ICMP ]###
     type      = echo-reply
     code      = 0
     chksum    = 0x0
     id        = 0x0
     seq       = 0x0
     unused    = ''

```

# Follow on

That should get you started with `scapy` and is enough to do a big stride in the
labs. For more information, please check out `scapy`'s
[documentation](https://scapy.readthedocs.io/en/latest/extending.html#).

