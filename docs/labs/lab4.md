---
layout: page
title: Lab 4
last_modified_date: Mon Feb 10 23:21:59 EST 2025
current_term: Winter 2024-25
nav_order: 80
parent: Labs
lab_dir: lab4
nav_exclude: false
description: >-
  Lab 4 instructions
---

## Table of contents
{:.no_toc}

1. no_toc
{:toc}

---

# Introduction

In this lab, you will explore using stateful firewalls to implement port
knocking, an approach in which the firewall hides certain protected ports from
users unless they know a _secret_ knocking sequence.

# Learning objectives

At the end of this lab, you should be able to:

- Define `nftables` sets and how they can manipulated.
- Define port knocking as a way to hide certain ports behind a firewall.
- Implement a simple port knocking firewall.
- Implement a more involved sequence of port knocking that mixes up TCP and UDP
  ports.

# Logistics

For this lab, we will be using GitHub classroom to get the starter code. Please
follow this [link](https://moodle.rose-hulman.edu/mod/url/view.php?id=4783832)
to accept the assignment and obtain your own fork of the lab repository.

{: .important }
The first time you accept an invitation, you will be asked to link your account
to your student email and name. Please be careful and choose your appropriate
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

## Network Topology

In this lab, we have a web server protected by a firewall and a client sitting
on a different subnet trying to reach the server.

 ```
 | ------ |                | -------- |                | ------ |
 | Client | -------------- | Firewall | -------------- | Server |
 | ------ |  10.10.0.0/24  | -------- |  10.10.1.0/24  | ------ |
 ```

---

# Experiment 0: `nftables` sets

Before we get started, we'll need to introduce an additional feature of
`nftables` that will prove useful with stateful firewalls, and that is the
ability to create and modify sets. A set is simply a kernel data structure that
holds some information which you can use to perform match operations.

For example, you can define a specific set of IPv4 address that you would want
to allow, and then drop everything else. Let's go ahead and do this.

## Step 1: Simple set

Create an `nftables` script and then add the following to it:

```sh
#!/usr/sbin/nft -f

# create a table
add table ip step0

# create the set
add set step0 allowed_ip {
  type ipv4_addr ;
  comment "set of allowed ip addresses " ;
  elements = { 10.10.0.4, 10.10.0.5 } ;
}

# add a chain hooked on the forwarding end
add chain step0 firewall { type filter hook forward priority 0 ; policy drop ; }

# add a rule to accept and count allowed ips
add rule step0 firewall ip saddr @allowed_ip counter accept
```

This will create a simple table called `step0` and with a forwarding chain
called `firewall`. Additionally, we create a set called `allowed_ip`, we
specify its type as `ipv4_addr` and then add some elements by default to it.

We finally add the rule `ip saddr @allowed_ip counter accept`. This rule will
apply to any packet with a source IPv4 address that matches **any** of the
possible values in the set `allowed_ip`. If a match occurs, then the action
taken is `counter accept` which keeps track of the received packets and accepts
them. You can use `nft list table step0` to see the content of the table.

## Step 2: Finding the bug

After installing the above rules, go ahead and try to `ping` the server
container from the client container, you should not be able to do so.

### Question sheet

List the content of your table and answer the following question:

1. Why is the firewall rule preventing the client from successfully pinging the
   server?

   _Hint_: If you're struggling here, you might find it useful to start a
   packet capture session on the server and the firewall and see where the
   packets are being dropped.

## Step 3: Debugging and fixing the bug

To help us understand what is going on even better, we can ask `nftables` to
log what is going on with the firewall rules. Let's go ahead and do that.

First, add a new chain to the table, but have it run before the `firewall`
chain (I am doing this from the command line, but feel free to append to your
script):

```sh
sudo nft add chain ip step0 trace_debug { type filter hook forward priority -100 \; }
```

Then add a tracing rule as follows:

```sh
sudo nft add rule step0 trace_debug ip protocol icmp meta nftrace set 1
```

This rule will enable tracing for all ICMP packets received on the `forward`
chain. To start viewing the trace, on the firewall container terminal, do the
following:

```sh
sudo nft monitor trace
```

Then try the ping again from the client to the server, you will see the trace
show up as the packets are processed. Note that the trace will print out packet
information at **each chain** of **each table**, so you will see things related
to the tables defined by `docker`, please ignore those as they won't impact
your packets in this experiment.

### Question sheet

Based on the trace logs, answer the following question:

1. Explain by referencing the logs what seems to be the bug in the current set
   of rules in the `firewall` chain.

2. Suggest a way to fix the rules in the `firewall` chain so that the two-way
   communication between the client and the server can complete.

### Hint: More syntax

If instead of adding IPv4 addresses individually, you'd like to add a range of
addresses (i.e., a subnet), you can add the flag `interval` to the set
definition and then add the ip addresses using CIDR subnet syntax. For example,
to add the entire subnet `10.10.0.0/24` to the set `allowed_ip` above, you can
do:

```sh
add set step0 allowed_ip {
  type ipv4_addr ;
  flags interval ;
  comment "set of allowed ip addresses defined by range" ;
  elements = { 10.10.0.0/24 }
}
```

# Experiment 1: Dynamic sets

{:.warning}
Before starting this experiment, make sure to delete the table from the
previous experiment using `sudo nft delete table step0`.

In this previous experiment, the set we defined was static, i.e., we did not
change any of the elements in it based on the changes in the network. However,
in most times, we'd like to modify our rules based on observations we see
abut the traffic coming into the firewall. So we need a way to modify our sets
on the fly.

## Step 1: Timed entries

We will start from the table and rules we created in the previous experiment,
but we will add the flag `timeout` to the set we create as follows:

```sh
#!/usr/sbin/nft -f

table ip e1s1 {
  set allowed_ip {
    type ipv4_addr
    flags timeout,interval
    elements = { 10.10.0.4 timeout 45s }
  }

  chain firewall {
    type filter hook forward priority 0; policy drop;

    # allow everything coming out of the server
    ip saddr 10.10.1.5 accept

    # allow address from the outside to come in as well
    ip saddr @allowed_ip counter accept
  }
}
```

{:.highlight}
Note that here we have used a different syntax than we have done before. We
specified the table using the same format as what you see when use `nft list
table`; that is totally valid with `nftables` and it will automatically create
the commands for you based on this format. Feel free to use any format to
specify your tables, chains, and rules.

In the above table, we created a set called `allowed_ip` with the flags
`timeout,interval`. The `timeout` flag allows up to add timeout values for each
entry in your set. After the timer expires, the entry will be **deteled** from
the set.

Let's go ahead and explore this rule. Assuming your `nft` script is called
`e1s1.nft`, install the rules using `chmod +x e1s1.nft` and then `sudo
./e1s1.nft`. Quickly now, get on the client container and try to `ping` the
server, you should be successful.

You can view the timer entry for each element in your set by listing the table:

```sh
$ sudo nft list table e1s1
table ip e1s1 {
  set allowed_ip {
    type ipv4_addr
    flags interval,timeout
    elements = { 10.10.0.4 timeout 45s expires 37s924ms }
  }

  chain firewall {
    type filter hook forward priority filter; policy drop;
    ip saddr 10.10.1.5 accept
    ip saddr @allowed_ip counter packets 2 bytes 168 accept
  }
}
```

Then, 45 seconds later, you can check out what happens to your set using:

```sh
$ sudo nft list table e1s1
table ip e1s1 {
  set allowed_ip {
    type ipv4_addr
    flags interval,timeout
  }

  chain firewall {
    type filter hook forward priority filter; policy drop;
    ip saddr 10.10.1.5 accept
    ip saddr @allowed_ip counter packets 2 bytes 168 accept
  }
}
```

Now, if you try to reach the server from the client, your attempts will not be
successful since the IP address of the client container has been removed from
the set.

## Step 2: Updating timed entries

Setting a timeout value for a static set valued does not make much sense unless
we can refresh the timeout value and reset the timer based on certain
conditions. Set operations support the `update` action that can update the
entry in a set and refresh its timeout value.

## Interlude: Navigating chains

To help us write better rules, especially when it comes to modifying sets, we
will organize our rules as a tree of chains that a packet must traverse. So
far, we have seen chains that were associated with a certain type and hook,
however, we can also define **regular** chains.

A regular chain is one that does not see any packets by itself, it is not
associated with a certain type or hook, but is used to be _called upon_ by
another of our _base_ chains in the ruleset.

Let's take a small example and try to understand chains a bit better. Here's a
simple `nft` script:

```sh
#!/usr/sbin/nft -f

table e1s2 {
  # this is a regular chain
  chain icmp_chain {
    counter
  }

  # this is a based chain with a type and a hook
  chain firewall {
    type filter hook forward priority 0; policy drop;
    # send icmp traffic to the icmp chain
    ip protocol icmp jump icmp_chain
    # accept all icmp traffic
    ip protocol icmp accept
  }
}

```

In this sample script, we create a regular chain called `icmp_chain` that simply
counts all the packets that it sees. We then ask our base chain (called
`firewall`) to send any ICMP packets received to the `tcp_chain` using the
`jump` keyword in `nftables`.

Now install your rules on the firewall container and then attempt to ping the
server from the client container. You should see the counter in the
`icmp_chain` update as packets are sent and captured (I called my table e1s2,
adjust as you see fit).

```sh
$ sudo nft list table e1s2
table ip e1s2 {
        chain icmp_chain {
                counter packets 2 bytes 168
        }

        chain firewall {
                type filter hook forward priority filter; policy drop;
                ip protocol icmp jump icmp_chain
                ip protocol icmp accept
        }
}
```

### Question sheet

To navigate chains, `nftables` also provides another way to move between them,
namely `goto` instead of `jump`. Let's see the difference between the two.

First, modify the rule in the `firewall` chain to use `goto icmp_chain` instead
of `jump icmp_chain`. Find the handle for the rule using `sudo nft -a list
table e1s2` and then update the rule (my handle number was 4):

```sh
sudo nft replace rule e1s2 firewall handle 4 ip protocol icmp goto icmp_chain
```

Now try to ping the server from the client container again and answer the
following questions:

1. Does the ping packet get delivered to the server?

2. Does the ping packet get added to the counter in the `icmp_chain`?

3. Explain the difference between a `goto` to a chain and `jump` to a chain.

   **No, it is not that `goto` drops the packets and `jump` accepts them**.

   _Hint_: There are two ways for you to answer this question:

    - Trace the rules in this table using the debugging techniques from above
      and understand where each packet travels.
    - Add a counter to the second rule (`ip protocol icmp accept`) and then
      check which counters get updated with `jump` vs with `goto`. Then, change
      the `firewall` chain's default policy to `drop` and try again and report
      on your observations.

## Back to set updates

Now that we can navigate between chains, we are ready to start updating our
rules. Let's go back to our original `e1s1` table from the first step. Note
that however we can no longer use the **interval** flag with for our set since
we will be adding one IP at a time. We also removed the initial set of elements
as we will be updating those on the fly.

```sh
#!/usr/sbin/nft -f

table ip e1s1 {
  set allowed_ip {
    type ipv4_addr
    flags timeout
  }

  chain firewall {
    type filter hook forward priority 0; policy drop;

    # allow everything coming out of the server
    ip saddr 10.10.1.5 accept

    # allow address from the outside to come in as well
    ip saddr @allowed_ip counter accept
  }
}
```

Now let's add another chain that will add entries to the set as follows:

```sh
chain add_to_set {
  add @allowed_ip { ip saddr timeout 30s }
}
```

The rule installed in this regular chain is one that adds the source IP address
for all received packets to the set, with a timeout value of 30 seconds.
Finally, we need to have a trigger that will cause this `add_to_set` regular
chain to be called up. For simplicity, we will assume that any ICMP packet
received from an IP address will cause that address to be added to the set.
Therefore, we'd need a rule of the following form: `ip protocol icmp jump
add_to_set`.

Our final `nftables` script would look like:

```sh
#!/usr/sbin/nft -f

table ip e1s1 {
  set allowed_ip {
    type ipv4_addr
    flags timeout
  }

  chain add_to_set {
    # set update ip saddr timeout 30s @allowed_ip
    add @allowed_ip { ip saddr timeout 30s }
  }

  chain firewall {
    type filter hook forward priority 0; policy drop;
    # allow everything coming out of the server
    ip saddr 10.10.1.5 accept
    # send icmp packets to the add_to_set chain
    ip protocol icmp jump add_to_set
    # allow address from the outside to come in as well
    ip saddr @allowed_ip counter accept
  }
}
```

### Question sheet

Install your table in the firewall and then first attempt to start a `telnet`
connection from the client to the server (`telnet server` from the client
container).

1. Should you be able to establish a `telnet` connection between the client and
   the server?

2. If your answer to the question above is no, what would you need to do to
   allow the client to talk to the server over `telnet`?

After you are able to allow the client to talk to the server, establish the
`telnet` connection and answer the following questions:

1. How long do you expect the `telnet` connection to last? In other words, what
   will happen to the `telnet` connection after 30 seconds?

To help in answering that question, have the client container issue an ICMP
echo request every 5 seconds to the sever. You can do so using the `-i` flag of
`ping` as follows: `ping -i 5 server`. During this time, monitor the content of
the `allowed_ip` set in the table using `nft list table e1s1`.

1. What do you notice about the entry for the client's IP address in the
   `allowed_ip` set? What does that tell you about the behavior of the `add`
   operation in the `add_to_set` chain?

Now replace the `add @allowed_ip { ip saddr timeout 30s }` with `update
@allowed_ip { ip saddr timeout 30s }` and then rerun the above exercise.

1. What do you notice about the behavior of `update` vs that of `add`?

Finally, answer the following conceptual questions:

1. What would happen if we had replaced the `jump add_to_set` action with `goto
   add_to_set` in the `firewall` chain? Explain your answer.

2. What would happen if we swap the order of the last two rules in the
   `firewall` chain? i.e., our chain would look like:
   ```sh
   ip saddr @allowed_ip counter accept
   ip protocol icmp jump add_to_set
   ```

# Experiment 2: Port knocking

Finally, let's solve our dilemma from the last concept lab. In the last
experiment we did above, we only allowed the client to reach the server if it
first sent an ICMP echo request packet. Once that packet is received, we allow
traffic between the client and the server to flow. Periodically, the client
would need to send echo request packets to refresh the timer in its firewall
entry and maintain the connection alive.

In this last experiment, we'd like to do better than using an ICMP echo request
to unlock access to the server. We will rely on our client having to know a
secret knock in the form of attempting to establish a connection on a sequence
of port numbers. After the client has done the secret knock, the communication
between the client and the server will be unlocked. This will make sure that
attackers that do random port scans on our network will not be able to
accidentally unlock access to the server; only those who know the secret knock
will be able to do so.

## Step 1: Warming up

Let's start with an easy case. We will want to protect port 23 (i.e., the
`telnet` port) on the server from being accessed by those who do not know the
secret knock. Our knock in this case will be very simply: send a TCP SYN packet
on port 9587 before you attempt to start the connection on port 23.

Here are the requirements:

1. If you attempt to connect to port 23 without knowing the secret knock, your
   traffic will be blocked.

2. After sending a SYN packet to port 9587, you have 10 seconds to start your
   telnet connection. If you do not do so, you will have to restart the knock
   sequence.

3. If you send traffic on any other port after starting the knock sequence, you
   will have to restart the sequence again.

   For example, say a client sends a packet to port 9587. They will have 10
   seconds to establish the connection to port 23. However, in those 10
   seconds, they send out a packet to port 443, at this point, they will have
   to restart the knock sequence.

   ```text
   Time 0: Client sends SYN on port 9587

   Time 1 (<10): Client sends packet on port 443 ==== sequence cancels

   Time 2 (<10): Client sends packet on port 23  ==== packet dropped, need to restart the sequence!
   ```

4. The client will need to refresh their access to the server every 45 seconds.

5. No traffic to any other port or any other protocol should be allowed to
   reach the server container.

### Hints

Here are a few hints:

- To remove an entry from a set, you can use this rule:
  `update @my_set { ip saddr timeout 0 }`

- The order of your rules **matters**, be intentional about how you approach
  ordering your rules.

- To match a certain TCP port number, you can use `tcp dport 9587` for the
  destination port and `tcp sport 9587` for the source port.

- You can also match ports that are not equal a certain port, for example:
  `tcp dport != 23` to match any port other than 23.

- To match TCP packets with **only** the `SYN` flag, you can use:
  `tcp flags == syn`.

### Testing

To test your script, you will need to generate TCP packets with specific flags
on demand. You can write your own scripts to do so, but there is a great tool
that allows you to do so, namely `hping3`. Check out the man page for `hping3`
for a full list of what you can do. Below we list out a few things that are
useful for our experiment.

1. To generate a TCP syn packet at port 9587 you can use;
   `hping3 -c 1 -S -p 9587 server` on the client container.

2. Similarly to generate a syn packet at port 23, you can use:
   `hping3 -c 1 -S -p 23 server`.

3. To start the `telnet` session, you can use `telnet server` on the client
   container.

To test rule 1, simply start a `telnet` connection and it shouldn't go through.

To test rule 2, send a syn packet to port 9587 using `hping3 -c 1 -S -p 9587
server` and make sure that your table has updated. Then, wait for 10 seconds,
and make sure that your table have updated correctly again.

To test rule 3, first send a syn packet using `hping3 -c 1 -S -p 9587 server`
and make sure that the table has updated. Within 10 seconds, send another syn
packets to any other port (other than 23) using `hping3 -c 1 -S -p 9588
server`.

To test correct port knocking sequence, you can use `hping3 -c 1 -S -p 9587
server ; telnet server` and the telnet session should be established and you
can login.

To test rule 4, make sure the `telnet` connection is established and wait for
45 seconds before trying to type anything in the `telnet` terminal, it should
hang and you will not be able to execute any commands (to exit our of it using
`c-]` - i.e., control and `]` and then type `q` or `quit`).

Testing rule 5 should be easy.

Finally, to check that only syn packets are able to trigger the port knocking
sequence, try the following `hping3 -c 1 -S -A -p 9587 server ; telnet server`.
This will send a TCP packet with both SYN and ACK flags set, which should not
trigger the port knocking sequence and thus must not allow the telnet session
to take place.

## Step 2: A bit better

In this step 2, we'd simply like to relax rule number 4. Once a connection is
established, we should allow it to stay alive even if the timeout period (of 45
seconds) has expired. As long as the connection is alive, the client and the
server should still be able to communicate. Once that connection is dead, the
port knocking sequence should be done again to establish a new connection.

_Hint_ This should be a very simple rule to add, nothing much else will change.

### Testing

To test this one out, establish a connection from the client to the server
after doing the port knocking sequence. Keep the connection alive for more than
45 seconds and make sure that your firewall table has been updated to reflect
that. Then check if the telnet session is still active. If it is, you should be
good to move on.

## Step 3: Full port knocking

In this final step, we'd like to mix things up a bit and do a real port
knocking sequence. The problem with what we did in step 1 and step 2 was that
we asked for only one port to be "knocked" before we accept `telnet`
connections. That is not ideal since an attacker might easily guess this or do
a brute force attack; at the end of the day, there are only $$2^{16}$$ port
numbers and it is not hard to try them all out.

In this step, modify your rules to create a sequence of port numbers that mixes
up TCP and UDP ports to finally unlock port 23 for `telnet` connections. The
sequence was ask you to implement is the following:

```text
TCP port 9587 --> TCP port 9090 --> UDP port 1234 --> TCP port 5978 --> unlock!
```

So our user must send packets with this exact port sequence for them to be able
to establish a `telnet` connection to the server. The rules for this setup are
the same as the rules in step 2 (i.e., established connections should not need
to restart the port knocking sequence every 45 seconds).

### Question sheet

Before you write down the script for your rules, on your question sheet, please
draw a _finite state machine_ that represents the possible states that your
firewall might be in when receiving packets.

# Reflection

In this lab, we have used port knocking as a way to make sure that our users
can _authenticate_ to the firewall so that the firewall can unlock certain
ports for them on the protected network.

In the space below (on the question sheet), think about possible ways in which
this approach can be broken down. There are two major limitations with this
approach that we'd like to tackle in the next concept lab.

# Submission

Submit your question sheet and your scripts for the experiments to Gradescope.

