---
layout: page
title: Transport Control Protocol
last_modified_date: 2025-01-14 09:43
current_term: Winter 2024-25
nav_order: 15
parent: Concepts
description: >-
  Instructions for setting up TCP experiment.
---

## Table of contents
{:.no_toc}

1. TOC
{:toc}

---

# Introduction

In this concept lab, we will explore the basics of the Transport Control
Protocol (TCP) and understand how it operates. We will run a few experiments
using `netcat` and `telnet` and explore how TCP helps those two services
operate. That would allow us to explore the possible vulnerabilities in TCP so
that we could exploit them later on in the class.

# Learning objectives

At the end of this session, you should be able to:

- Identify the steps involved in the TCP protocol.
- Explore the TCP session setup steps.
- Identify vulnerabilities in the TCP protocol.

# Logistics

<!-- TODO: Add link to Github classroom assignment here... -->
For this lab, we will be using GitHub classroom to get the starter code. Please
follow this [link](https://moodle.rose-hulman.edu/mod/url/view.php?id=4759706)
to accept the assignment and obtain your own fork of the lab repository.

{: .important }
The first time you accept an invite, you will be asked to link your account to
your student email and name. Please be careful and choose your appropriate
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

The topology for this minilab consists of only two machines, a server and a
client. The client has the IPv4 address of 10.10.0.4 while the server has the
IPv4 address of 10.10.0.5.

---


# Experiment 1: TCP connection establishment

For this first experiment, we will capture traffic related to an established
TCP session between a `netcat` client and server. To launch the experiment,
bring up your environment and grab three terminals: 2 on the server and one on
the client.

On the server end, start a packet capture for TCP traffic:
```sh
sudo tcpdump -i eth0 tcp -w /volumes/experiment_1.pcap
```
and in the other terminal, start a `netcat` server using:
```sh
nc -n -v -l 1234
```

On the client side, connect to the server using:
```sh
nc server 1234
```

In this experiment, we will not send any data through the `netcat` session, we
will just open it and see what packets are exchanged between the client and the
server. Just leave the client running but do not enter any data in the window.

Stop the packet capture on the server end using `C-c` in the `tcpdump` window,
the capture file will be saved under `volumes/experiment_1.pcap`.

Download the `pcap` file to your local machine and open it using `Wireshark`,
you should see exactly three TCP packets. So before any data is exchanged, the
client and server have negotiated the setup of the connection using these three
packets.

## Question sheet

Observe the three packets that show up, and answer the following questions:

1. How does a client initiate a connect request with the server?

2. If the server is ready to accept a connection, how does it tell the client
   so?

3. What does the client do when it receives the server's confirmation?

4. Open the TCP header fields, which part of the TCP header dictates the type
   of the packet?

5. Why do you think the server expects the client to respond back to confirm
   the connection's establishment (i.e., why do we need a third packet)?

# Experiment 2: Reaching a down server

Let's now repeat the experiment, but without having the server running. In
other words, do not start the `netcat` server on the server container, simply
try to connect to the server from the client.

Run a packet capture for TCP traffic on the server end:
```sh
sudo tcpdump -i eth0 tcp -w /volumes/experiment_2.pcap
```

On the client, attempt to connect to the server using:
```sh
nc server 1234
```

Obviously, the connection will fail, let's see how the server informs the
client of that. Stop the packet capture on the server, and download the
generated `experiment_2.pcap` file.

Open the packet capture file and observe the behavior of the server.

## Question sheet

Based on your observations, answer the following questions:

1. What does the server container do when it receives a connection request for
   a service that it does not normally provide?

2. What happens at the client when it receives that information?

3. Do you notice any potential problems with this particular option in the
   TCP protocol?

# Experiment 3: Trying a non existing server

Before we get to the meat with things, let's try to see what happens if we try
to reach a non-existing server. For this experiment, we will need two
terminals at the client, the server containers won't be involved. We would like
to talk to the non-existing server `10.10.0.80`.

On the client, start a packet capture for TCP packets using:
```sh
sudo tcpdump -i eth0 tcp -w /volumes/experiment_3.pcap
```

Before we can actually try this experiment, we need to do a little trick to see
the behavior desired. If the server we are trying to access (say `10.10.0.80`)
is not on the network, then the ARP requests from the client to that IP address
will fail, which means that no TCP packets will ever leave the client.

In this experiment, we will inject an entry in the ARP cache of the client to
convince it that that particular server exists, even if it does not.
Fortunately, we won't write an exploit for that, we can do it from the client
using:
```sh
sudo arp -s 10.10.0.80 02:32:0a:0a:00:06
```

Then from the other terminal window, try to reach a server that is not on the
network, let's try for `10.10.0.80`.
```sh
nc 10.10.0.80 1234
```

The `netcat` client would hang for a bit (give it a minute or two), then it
will exit. Store the packet capture once the process dies, download it, and
open it using `Wireshark`.

## Question sheet

Observe the behavior of the client when trying to reach the non-existing server
and answer the following questions:

1. By default, what does the client do when it does not hear a response from
   the server to its `SYN` packets?

2. How many times does the client try to connect before giving up (in addition
   to the first one)?

3. On the client machine, check out the value in `cat
   /proc/sys/net/ipv4/tcp_syn_retries`, what do you notice?

4. Observe the timestamps at which the packets are sent, what can you say about
   the intervals between packet retries (approximately)?

5. Based on the above three experiments, draw a finite state machine diagram
   that represents the TCP connection establishment phase. We refer to this
   phase as the TCP **three-way-handshake**.

# Experiment 4: Closing a connection

Next, we would like to explore how a TCP connection is closed by either ends.
We have already seen one way to do so in experiment 2, namely by sending a TCP
Reset packet. But that is abnormal conditions, let's see how a TCP connection
is normally closed.

We will repeat the setup for experiment 1, but this time, we will close the
connection normally before stopping the packet capture.

On the server, start a `tcpdump` packet capture using:
```sh
sudo tcpdump -i eth0 tcp -w /volumes/experiment_4.pcap
```
Then start a `netcat` server using:
```sh
nc -n -v -l 1234
```

At the client end, connect to the server using:
```sh
nc server 1234
```

Do not send any data over the connection, simply kill it using `C-c` on the
client. This will cause by the server and the client to stop the `netcat`
program and drop back into the shell. Once that happens, stop the packet
capture on the server side and download the packet capture to open in using
`Wireshark`.

## Question sheet

After the connection has been established using the regular three-way-handshake
that we discussed before, the connection is terminated by the client. Observe
the packet capture and answer the following questions:

1. How does the client signal to the server that it wishes to end the
   connection?

2. What does the server do when it receive a connection termination request
   from the client?

3. Why do you think the server waits for the client to confirm that it has
   received its acknowledgment of connection termination packet?

4. Assume that the server did not receive the client's acknowledgment, what do
   you think it will do at that point?

# Experiment 5: Exchanging data

Now it is time to start looking at the data exchange between the client and the
server. We will pretty much repeat the setup for experiment 4 all the while
exchanging data between the client and the server now.

On the server, start a `tcpdump` packet capture using:
```sh
sudo tcpdump -i eth0 tcp -w /volumes/experiment_5.pcap
```
Then start a `netcat` server using:
```sh
nc -n -v -l 1234
```

On the client's side, start a connection to the server using:
```sh
nc server 1234
```

Now, anything you type on the client's side will show up at the server's side
(it will be simply echoed on the standard output at the server's end). To keep
things consistent, let's try to send the following three messages through the
connection (hit `Enter` after each one to make sure it is sent separately).

1. Send `Hello`, make sure it shows up on the server's side.
2. Send the paragraph below, you can copy and paste it from here, make sure it
   shows up on the server's side.

   ```
   Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
   tempor incididunt ut labore et dolore magna aliqua. Purus semper eget duis
   at. Nulla malesuada pellentesque elit eget gravida cum sociis natoque
   penatibus. Senectus et netus et malesuada fames ac turpis egestas sed. Purus
   in mollis nunc sed. Nam at lectus urna duis convallis. Sit amet consectetur
   adipiscing elit duis. Dui faucibus in ornare quam. Lobortis elementum nibh
   tellus molestie nunc non blandit massa. Pellentesque nec nam aliquam sem et
   tortor. Augue lacus viverra vitae congue. Viverra vitae congue eu consequat.
   ```

3. Send `Goodbye` and end the connection using `C-c`.

After sending these three messages, stop the packet capture at the server end
and download the packet capture file to open it with `Wireshark`.

## Question sheet

Please note that the number of packets you will see might vary, so it's okay if
it doesn't always appear the same. We are only interested here in the packets
between the end of the three-way-handshake and the start of the connection
termination step. For me those were packet 4 through 15, but the end number
might be different for you.

Observe the packet capture and answer the following questions:

1. What flags are set in the packets that contain data in `netcat`?

2. What does the server do when it receives a data packet from the client?

3. For the packets between the connection establishment and tear-down, fill out
   the following table with the following fields:

   - The _sequence number_ that you can obtain from the TCP header (use the
     relative number printed out by Wireshark).
   - The _acknowledgment number_ that you can obtain from the TCP header (also
     use the relative one shown by Wireshark).
   - The TCP segment length that you can find in the TCP header or in the
     packet summary in Wireshark.
   - In the table, `C -> S` represents a packet sent from client to server,
     while `S -> C` represents a packet sent from the server to the client.
   - If you have less packets that the rows here, that's okay, fill out the
     ones you have.

    | Packet Number | Sequence Number | Acknowledgment Number | TCP Segment Len |
    |---------------|-----------------|-----------------------|-----------------|
    | 4   `C -> S`  |                 |                       |                 |
    | 5   `S -> C`  |                 |                       |                 |
    | 6   `C -> S`  |                 |                       |                 |
    | 7   `S -> C`  |                 |                       |                 |
    | 8   `C -> S`  |                 |                       |                 |
    | 9   `S -> C`  |                 |                       |                 |
    | 10  `C -> S`  |                 |                       |                 |
    | 11  `S -> C`  |                 |                       |                 |
    | 12  `C -> S`  |                 |                       |                 |
    | 13  `S -> C`  |                 |                       |                 |
    | 14  `C -> S`  |                 |                       |                 |
    | 15  `S -> C`  |                 |                       |                 |

4. Based on the content of the table above, what is relationship between the
   **sequence number**, the **acknowledgment number**, and the **segment
   length**?

5. Assume now that we have a network that is very unstable, where packets can
   be delayed in the way, or even lost. How can the client and the server use
   the sequence and ack numbers to still communicate even if the medium is
   unreliable?

6. Examine any packet containing data, you can see that `Wireshark` is printing
   a relative sequence number, while the real sequence number starts off very
   weird. Why do you think we need the sequence number to start at a very weird
   random location?

# Experiment 6: Observing `telnet`

Finally, we will explore a different application that runs over TCP, namely the
`telnet` service. `telnet` is kind of the predecessor for `ssh` where a remote
client can login to a server and access a shell to issue commands. For good
reason, `telnet` should generally not be used as it does everything in plain
text, including authentication, so we normally just use it for debugging and
testing.

The server has already been configured to host a `telnet` service; you can
login to it with the username `root` and the password `netsec`. Our goal here
is to examine a `telnet` session and see how authentication and data exchange
happen.

On the server end, start a packet capture session, just like the previous
experiments:
```sh
sudo tcpdump -i eth0 tcp -w /volumes/experiment_6.pcap
```

On the client side, start a telnet session as follows:
```sh
telnet server
```

You will be prompted for the username and password, once you enter those, you
will be dropped into a root shell session that you can use to issue commands.
You can use `root` as the username and `netsec` as the password.

For simplicity, from the created shell, let's just print the current working
directory using `pwd`.

When you issue a command, it will be executed on the server, but the output
will show up on the client's side. To avoid bloating the packet capture, let's
just exit the shell (using `C-d` or `exit`). This will close the connection by
default.

Once done, stop the packet capture session at the server and download the
packet capture file.

## Question sheet

Let's examine the packet capture and see how `telnet` operates. First, there
will be a configuration or negotiation phase; we will not bother ourselves with
it, we will simply skip over it. Our first point of interest is when the user
enters the username they wish to use for the session.

To help us find the packet, we can use the search option in `Wireshark` to find
the `server login:` prompt sent by the server. To do so, start a search using
`C-f` in the `Wireshark` window. This will open small sub-menu.

To find the string let's set the options, from the first drop down menu, select
`Packet bytes`, leave the second as is, then in the third one, select `string`
and enter `server login:` as the search key. If all goes well, you should be
dropped to the packet that contains that string, for me, that was packet number
24.

Observe the next few packets after it, and answer the following questions:

1. How does the client send its username to the server?

2. How does the server respond to each packet sent by the client when entering
   the username? Who does the acknowledgments?

Next, use the search bar to find the `Password:` prompt sent by the server. As
we mentioned, you will find the user's password in plaintext in the next few
packets. Examine those packets and answer the following questions:

1. How does sending the password differ (in terms of the communication) between
   the client and the server?

Finally, find the `pwd` command in the packets. You'll have to look for it a
bit, and _hint_ it will not be contained in a single packet. Once you find it,
answer the following questions:

1. How are commands sent from the client to the server?

# Food for thought

Consider now a scenario where you are on a network and can sniff packets going
over this network. However, the network admin, being sneaky, has configured
static ARP mappings, i.e., you cannot perform an ARP cache poisoning attack.
However, you'd still like to grab a root shell on a target server on the
network.

Luckily, while listening on the network, you find yourself in the middle of an
already established `telnet` between an admin machine and your target server.
By observing the network packets, what can you do to be able to run arbitrary
commands, **without interruption**, from your malicious machine on the target
server?

Think about this for a while, that would be the topic of our next lab.

## Question Sheet

Please summarize what you have learned about the TCP protocol. Make sure to
mention who connections are established, how they are terminated, and how is
data arranged.

When it comes to the `Telnet` protocol, list out any potential
vulnerabilities you might think of if you were able to sit in the middle
between the server and the client.


