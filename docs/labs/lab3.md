---
layout: page
title: Lab 3
last_modified_date: Sun Jan 19 11:28:55 EST 2025
current_term: Winter 2024-25
nav_order: 40
parent: Labs
nav_exclude: false
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

# Tools

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

# Logistics

<!-- TODO: Add link to Github classroom assignment here... -->
For this lab, we will be using GitHub classroom to get the starter code. Please
follow this [link](https://moodle.rose-hulman.edu/mod/url/view.php?id=4762232)
to accept the assignment and obtain your own fork of the lab repository.

{: .important }
The first time you accept an invite, you will be asked to link your account to
your student email and name. Please be careful and choose your appropriate
name/email combination so that I can grade appropriately.

## Generating your `.env` file

Before we spin up our containers, there are some configuration variables that
must be generated on the spot. To do so, please run the `gen_env_file.sh`
script from the lab repository directory as follows:

```shell
$ ./gen_env_file.sh
```

If run correctly, several files will be generated:

1. `.env` (hidden file - use `ls -al` to see it) contains your UID and GID
   variables.

2. `connect_*.sh` a utility script to quickly connect to each container in this
   lab.

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
your packet injection starter code can be found in the file `hijack_conn.c`.

Examine `route.c` and `hijack_conn.c` to understand what they are trying to do.
Once you are ready, compile the code in the `route` directory using `make`; the
binary `route.bin` should be generated.

## Testing basic routing

To make sure everything starts off correctly, bring up your environment using:
```sh
dcupd
```
and then grab a terminal at the client and **two** on the attacker.

The routing code will have to run in two separate processes since we would like
to handle bi-directional communication. Therefore, in one attacker terminal
window run:
```sh
cd /src/route/
sudo ./route.bin -i eth0 -o eth1
```
and on another attacker terminal, run
```sh
cd /src/route/
sudo ./route.bin -i eth1 -o eth0
```

This will instruct the `route.bin` program to listen on both interfaces to make
sure you can forward traffic correctly.

{:highlight}
Feel free to put those two commands in a script to ease up the launching of
the attack. I preferred to keep them on separate terminals to be able to debug
and see what's going on for each interface on the attacker router.

From the client terminal, try to reach the server first using `ping`:
```sh
ping -c 10.10.1.15
```

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

This piece of code checks if a TCP packet has been detected, and then computes
its checksum value. However, if the packet contains both `PUSH` and `ACK`
flags, we will check for the specific trigger using `is_triggered` and then
launch the attack using `hijack_tcp_connection`.

The function `is_triggered` and `hijack_tcp_connection` can be found in the
`hijack_conn.c` file. This is where you will add your code. I have already
provided you with a skeleton of what you need to do along with a bunch of
`TODO` statements where you need to add your edits.

Start by writing your own `trigger` function and then launch the attack by
modifying the `hijack_tcp_connection` function. Here is one possible plan of
attack.

1. Write your trigger function and make sure it is working correctly. I would
   do that by adding a simple print statement in the `hijack_tcp_connection`
   function, which would do nothing else.

   To pretty much cancel out the `hijack_tcp_connection` function, simple add a
   print statement followed by `return 0;`, making the rest of the code dead.

2. Then read the code in `hijack_tcp_connection` and understand what it is
   trying to do. Make sure to ask any questions as you go along with it.

3. Create a plan for the different fields that you must fill out in
   `hijack_tcp_connection`. Please do not try to write them out and then think
   about them. Make sure you understand what each field is doing and what its
   appropriate value would be.

4. Launch your experiment and test things out.

   {:.warning}
   Make sure to delete the file `/volumes/pwnd.txt` between runs of the
   experiment to make sure that what you are seeing is the result of the
   current experiment, and not something done before.

# 3. Establish a reverse shell

If you have done part 2 if this lab, this should be a slight modification on
it, based on the experiments you have done in the reverse shell concept lab.
Your attack in this experiment would be successful if you can have a server
shell running on the attacker machine, from which you can execute any arbitrary
command.

Once your attack is successful, please take a screenshot showing the server
shell running on the attacker for submission.

# Submission

Please submit your source code along with screenshots of your successful attack
to Gradescope.


