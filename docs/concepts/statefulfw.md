---
layout: page
title: Stateful Firewalls
last_modified_date: Thu Feb  6 12:40:41 EST 2025
current_term: Winter 2024-25
nav_order: 70
nav_exclude: false
parent: Concepts
description: >-
  Instructions for create stateful firewalls
---

## Table of contents
{:.no_toc}

1. no_toc
{:toc}

---

# Introduction

So far, in creating our firewalls, we were only looking at single packets
coming into our system, we do not retain any state about the packets or the
connections that are established throughout (outside of simply couting
packets). This is referred to as stateless firewall.

In this concept lab, we would like to augment our firewalls to retain **state**
about the packets that are sent through it, and to make decisions based on the
state of certain connections and some packet manipulations done.

# Learning objectives

At the end of this concept lab, you should be able to:

- Define how a stateful firewall works in the context of a Linux box.
- Experiment with different stateful rules that are based on network
  connections, rather than individual packets.

<!--
- Use network address translation to access a subnetwork that was previously
  not accessible.
-->

# Logistics

For this lab, we will be using GitHub classroom to get the starter code. Please
follow this [link](https://moodle.rose-hulman.edu/mod/url/view.php?id=4780223)
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

## Network Topology

You can find the network topology for this lab below:

```txt
+-------------------+          +-------------------+           +-------------------+
|    client2        |__________|    firewall       |___________|    server         |
|  IP: 10.10.0.5    |   |      |  IP: 10.10.0.10   |     |     |  IP: 10.10.1.4    |
+-------------------+   |      |  IP: 10.10.1.10   |     |     +-------------------+
                        |      +-------------------+     |
                        |                                |
+-------------------+   |                                |     +-------------------+
|    client1        |___|                                |_____|    workstation    |
|  IP: 10.10.0.4    |                                          |  IP: 10.10.1.5    |
+-------------------+                                          +-------------------+
```

---

# A stateful firewall

We will start by looking at the possible connection tracking techniques that we
can employ to make routing decisions based on the states of connections, rather
than individual packets.

At this point, all machines on either subnet can access and reach each other.
To confirm that, grab a terminal window on `clien1` and try to `telnet` into
the server (username is `root` and password is `netsec`). You should be able to
establish the connection and obtain a shell on the server.

Next, we would like to perform actions on a connection-basis rather than on a
packet basis. First, using the techniques from the previous two concept labs,
create a `nftables` table (I called mine `fw_tbl`) and in it, create a chain on
the `forward` hook with its default action being `drop`.

Check if your table and chain are created using `nft list table fw_tbl`. We
don't have any rules yet, we have only set up the chain. Before you install the
table, please grab a terminal on either of the clients, and start a `telnet`
session to the server.

```sh
(client1) $ telnet server
Trying 10.10.1.4...
Connected to server.
Escape character is '^]'.

Linux 6.1.0-10-amd64 (server) (pts/1)

server login: root
Password:
Linux server 6.1.0-10-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.37-1 (2023-07-03) x86_64

The programs included with the Kali GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Kali GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Thu Feb  1 16:07:13 UTC 2024 from 10.10.0.4 on pts/1
┏━(Message from Kali developers)
┃
┃ This is a minimal installation of Kali Linux, you likely
┃ want to install supplementary tools. Learn how:
┃ ⇒ https://www.kali.org/docs/troubleshooting/common-minimum-setup/
┃
┗━(Run: “touch ~/.hushlogin” to hide this message)
┌──(root㉿server)-[~]
└─# ls

┌──(root㉿server)-[~]
└─#
```

{:.warning}
Please keep this session alive before you move on to the next step.

Next, let's add the following rule to out table (please adjust the table name
and chain name to the ones you have chosen). In my script, I added the
following (my table is called `fw_tbl` and my chain is called `fwd_chain`):

```sh
add rule fw_tbl fwd_chain ct state established,related counter accept
```

## Question sheet

Now, let's find out what this rule has done. Go back to the telnet session you
had already started on `client1`. Try to use that `telnet` session and check to
see if you can still access the server.

From `client2`, grab a terminal and attempt to start a new `telnet` session on
the server using `telnet server` and see if you can reach the server. Also try
to reach the server using `ssh` and `ping`.

1. Is the `telnet` from `client1` still active?

2. Can you access the `server` from `client2`?

Next, get another terminal on `client1` (do not kill the telnet session) and
attempt to access the server again. First, attempt to ping the server using
`ping -c1 server`.

1. Are you able to `ping` the server from `client1`?

2. Also, try to start a new `telnet` session form the `client1`, are you able
   to do so?

Next, kill the `telnet` session on `client1` and then attempt to restart it
immediately.

1. Are you able to reestablish the `telnet` connection from `client1` to the
   `server?`

Based on all of your observations from above, answer the following question:

1. What do you think the rule `ct state established,related counter accept` is
   doing?

You might find listing the table to view the counter values very useful.

Finally, before you kill the session and delete the table rules, on the
firewall, run a `tcpdump` capture on the interface `eth0` and capture TCP
traffic (something like `tcpdump -i eth0 tcp -w /volumes/step1.pcap`) and then
attempt the `telnet` session from `client1` to the server again. Please keep
this packet capture handy for the next steps.

# Exploring `conntrack`

What allowed us to do the above tracking and maintenance of state is a Linux
kernel utility called `conntrack`. As its name suggests, it allows us to track
connection seen by the kernel as they are passing through, making some
heuristics in order to classify packets as being part of a connection or not.

In our rule above, we used the `ct state` match option to look at the
connection. `ct state` can have one of the possible values:

- `new`: packets on a new connection have only be flowing in one direction, so
  the connection is not yet established but might be in the process of doing so.

- `established`: the connection has valid packets traveling in both directions
  between a pair of hosts. For TCP, this means we have already established the
  three-way handshake we discussed in a previous concept lab.

- `related`: this is useful in the context of some protocols (like HTTP and
  FTP) that might open several connections as part of the same session.

- `invalid`: packets from an invalid session do not follow a typical expected
  behavior of a connection.

## Experiment 1

Let's experiment a bit with our previous rule by switching the policies. We
would like our firewall to `accept` packets by default but drop established or
related connections (this is a bit idiotic by let's try it).

Modify your firewall rules from the previous section to now accept all packets
except those part of an established connection. To test things out, first
clear our your firewall by deleting the table, then create an active `telnet`
session between `client1` and the `server` prior to installing the rules.

### Question sheet

Before you run your experiment, please answer the following question:

1. What do you expect the behavior of this firewall rule to be?

Next, while the telnet session is still active, install the firewall rules on
the firewall container, then answer the following questions:

1. What happens to the active `telnet` session (you can try to input anything
   or run any command to test it)? Why do you think that happened?

Next, let's try to establish a new connection on from either clients to the
server. From `client2`, try to `telnet server` to attempt to establish the
connection.

1. Was the `telnet` connection setup successful?

Let's examine what happened even further. On the firewall container, run a
packet capture on the `eth1` interface (i.e., the one connected to the server
subnet) and examine the packets that are flowing through. Then, please answer
the following question about the `telnet` connection.

1. Does the SYN packets sent from the client to the server reach the server?

2. Does the server reply to the packet? And does that packet ever make it back
   to the client?

3. Based on your answers to the above two questions, explain the difference
   between this experiment (where we accept everything except established
   connections) and the one from the first section (where we drop everything
   except established connections). Specifically, we are interested in the
answer to the question of _when are packets dropped_ by the firewall?

   You will find it useful to compare the packet capture from the previous step
   with this one to gain better clarity of where things are dropped.

   _Hint_: The firewall is connected to the clients subnet on `eth0` and to the
   server and workstation subnet on `eth1`.

## Experiment 2

In this experiment, we would like to further monitor and view the connection
directions. `conntrack` allows us to do so using the `ct direction` match rule,
which matches one of two possible values:

- `original`: this will match packets origination from the host who initiates
  the connection.

- `reply`: this will match packets originating from the host who replies back
  to the initiator.

Let's examine this through an experiment. First, delete the table you created
in experiment 1 and let's create a new one, with the same chain, but we will
change the rule. Make sure your default action in this chain to `accept`.

For the rules in this case, use the following in your script:

```sh
add rule fw_tbl fwd_chain ct state established counter
add rule fw_tbl fwd_chain ct state established ct direction original counter
```

Next, install the firewall rules and then start a `netcat` session from any of
the clients to the server. We will use `netcat` since it's a bit simpler and
not as verbose as `telnet`. So start a `netcat` listening server on the
`server` container using `nc -n -v -l 9090`. Before you connect from the
client, grab another terminal on the server and start a packet capture
(`tcpdump -i eth0 tcp`), no need to write it to a file unless you prefer it
this way.

### Question sheet

With your firewall rules installed and your packet capture running on the
server, connect the `netcat` server from either of the client containers, do
not send any packets after the connection is established.

On the firewall, observe the content of the table  (`nft list table fw_tbl`).
Answer the following questions.

1. How many packets show up in the `established` rule?

2. How many packets show up in the `ct direction original` rule?

3. How many packets show up in the packet capture on the `server`?

4. Do the number of those packets add up? If not, why do you think so?

### Task: Count all packets

In this task, you will need to modify the firewall rules above to capture all
of the following:

1. The packet first sent by the client to establish the connection, i.e., the
   first SYN packet in the case of TCP.

2. The reply packet sent back by the server in response to the `SYN` packet.

3. Any packets exchanged between the client and the server in the `netcat`
   session.

4. The number of packets capture by the firewall should match the number of
   packets capture on `tcpdump` on the server side.

{:.highlight}
_Hint_: To write the correct rules about this, you will need to ask yourself
the following question: what is the state and direction of each packet sent by
the client and the server in the case of a `netcat` connection.

Here's a sample output from my case when establishing a `netcat` connection
(and not sending anything else). I added four rules to do this (you might need
less or more depending on how you do it).

```sh
table ip fw_tbl {
  chain fwd_chain {
    type filter hook forward priority filter; policy accept;
    <Rule 1> packets 2 bytes 112
    <Rule 2> packets 1 bytes 52
    <Rule 3> packets 1 bytes 60
    <Rule 4> packets 1 bytes 60
  }
}
```

In total, there were three packets exchanged (`SYN`, `SYN/ACK`, and then `ACK`)
but one of my rules (the first one) double counts one of those. So in total, I
had three packets that all showed up in the firewall and in the packet capture.

# Motivating thought experiment

Say now you are designing your network and you have a webserver running on
TCP port 80. Since port 80 is a standard port, it is easy for attacker to
find out about it by doing a simple network scan, for example using
`nmap`. But we don't want that to happen, we would like to block port
scans from seeing the presence of port 80 on our protected network.

The first thing you can do is install a firewall at the perimeter of the
subnetwork hosting the webserver, but that is not enough since port 80 is
still exposed to the outside and still be reached by attackers attempting to
perform a port scan. We need something more.

In the space below, describe a way to hide port 80 away from everyone except
those that really know about it. Please note that we cannot filter based on
`IPv4` addresses since we cannot really tell from where our clients might
be coming from, so that is off the table.

Here's an analogy. I am hiding from `CSSE332` students in my office and I
do not want to open the door except for students from the network security
class, can you suggest a way for me to only open the door is I know that the
student at the door is not a `CSSE332` student and rather one from this
class?

