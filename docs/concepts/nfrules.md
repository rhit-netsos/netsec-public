---
layout: page
title: Introduction to Firewall Rules
last_modified_date: Thu Jan 30 02:56:04 EST 2025
current_term: Winter 2024-25
nav_order: 60
parent: Concepts
nav_exclude: false
description: >-
  Instructions for create firewall rules using nftables
---

## Table of contents
{:.no_toc}

1. no_toc
{:toc}

---

# Introduction

This concept lab follows directly after the `nftables` introductory concept
lab. Please use the same docker environment that you used in [that
lab]({{site.baseurl}}/docs/concepts/nftables).

# `nftables` scripting

In the last concept lab, we explored creating `nftables` tables and chains,
however we did those in the command line, which is not persistent, i.e., you
would have to retype the full command every time you reset your machine.

We can do a bit better using `nftables` scripts, so let's go ahead and do that
here to get started. To get started, under the `/volumes/` directory, create a
file called `netsec_tbl.nft` and add the following in it:

```sh
#!/usr/sbin/nft -f

# create the table netsec
#   note that we don't need to use nft here, simple start the command.
add table ip netsec_tbl

# create our first chain for incoming traffic
add chain netsec_tbl netsec_in { type filter hook input priority 0 ; policy accept ; comment "our first netsec chain" ; }
```

Next, make this script executable using `chmod +x netsec_tbl.nft` and then
execute it using `./netsec_tbl.nft`. To verify that the script executed
correctly, check the content of the table using (note that I reduced the indent
size for clarity):

```sh
$ sudo ./netsec_tbl.nft
table ip netsec_tbl {
  chain netsec_in {
      comment "our first netsec chain"
      type filter hook input priority filter; policy accept;
  }
}
```

# Adding rules

Now that we have our first chain, we can start adding rules to it. Let's start
with our first rule. Create another script, I called it `netsec_rules.nft`, as
follows:

```sh
#!/usr/sbin/nft -f

# include the file that creates the table and chain, so that we can mess around
# with the rules here
include "./netsec_tbl.nft"

# define some variables, adjust these for your ip addresses
define client_ip = 10.10.0.4
define server_ip = 10.10.1.4

# add our first rule
add rule netsec_tbl netsec_in ip saddr $client_ip counter
```

As you notice in the above script, we can include the previous file to create
the table using `include "./netsec_tbl.nft"`, this way you don't have to run a
different scripts to get everything together. You can also define variables,
such as the `client_ip` and the `server_ip`. Finally, we add our first rule:
```
add rule netsec_tbl netsec_in ip saddr $client_ip counter
```
Let's break this one down, `add rule` is simply the `nft` command we'd like to
execute. Here's the breakdown of the other parameters:
- `netsec_tbl` is the table in which our rule is to be added.
- `netsec_in` is the chain in that table where to add our rule into.
- `ip` specifies that we are looking to math IPv4 packets.
- `saddr $client_ip` specifies that we are interested in IPv4 packets whose
  source address match the client's IP address.
- `counter` is the action we'd like to take on matching packet. We will explore
  what this means next.

{:.warning}
Please make sure to adjust the `client_ip` and the `server_ip` variables to
contain the IP address of the client and the server specific to your
environment.

## Counters

After creating the rules script, execute it using:
```sh
sudo ./netsec_rules.nft
```
Verify that it run correctly using:
```sh
sudo nft list table netsec_tbl
```
My output looks something the following:
```sh
table ip netsec_tbl {
  chain netsec_in {
    comment "our first netsec chain"
    type filter hook input priority filter; policy accept;
    ip saddr 10.10.0.4 counter packets 0 bytes 0
  }
}
```

Now, from the client container, try to ping the firewall using `ping -c3
firewall` and then check again the content of the table.

## Question sheet

Based on your observations above, answer the following questions:

1. What do you think the `counter` rule is doing?

Next, from the client, try to reach the server using `ping -c3 server` and then
check the content of the table again.

2. Does the table change after the client pings the server? What in the
   `nftables` table and chain impact this outcome?

3. If you were to change the table or chain to apply the counter rule to the
   client to server traffic, what would your script look like? Make sure to
   write such a script and test it before submission.

## Flushing a chain

To remove all rules from a chain, you can **flush** that chain and drop it back
to its default policy specified when the chain was created. To do so, you can
use:

```sh
sudo nft flush chain netsec_tbl netsec_in
```

Recall that you can also delete that chain using `nft delete chain netsec_tbl
netsec_in`, if needed.

## Deleting a rule

If you'd like to just delete a rule, then you will first have to obtain that
rule's number from the table. You can do so by adding the `-a` flag to the
`nft` command as follows:

```sh
sudo nft -a list table netsec_tbl
```

On my container, here's my output:

```txt
table ip netsec_tbl { # handle 2
  chain netsec_in { # handle 6
    comment "our first netsec chain"
    type filter hook input priority filter; policy accept;
    ip saddr 10.10.0.4 counter packets 0 bytes 0 # handle 7
  }
}
```

You will notice that the rule that we added earlier now has comment next to it
showing its handle number `# handle 7` above. You can use this number to index
that specific rule that you wish to manipulate.

To delete that rule, you can use:
```sh
sudo nft delete rule netsec_tbl netsec_in handle 7
```
That rule will disappear from your table after that.

# Exploring actions

Let's now turn to making our rules take actions on the matching packets. An
obvious action would be _accept_ packet, another would be to _drop_ it, antoher
would be to _reject_ that packet. We will explore the difference between drop
and reject in the following section.

## Dropping packets

Let's start first by dropping all packets that are coming from the client
container and destined to the firewall itself. We will be doing our work in the
`netsec_tbl` table and its corresponding `netsec_in` chain.

Let's add our first rule as follows (feel free to put this in a script if you'd
like):

```sh
sudo nft add rule netsec_tbl netsec_in ip saddr 10.10.0.4 icmp type echo-request counter drop
```

Note that in this case our rule perform two actions: _counter_ and _drop_,
which means that we would like to count all ICMP echo request packets from the
client and then drop them.

Now, verify that the rule is working by trying to ping the firewall from the
client container. If your ping is not successful, then you should be good.

## Rejecting packets

Now let's modify the rule we added in the previous exercise. To do so, we must
obtain the rule's handle. To do so, use the `-a` flag just like we did before
and record the rule's handle.

To replace that rule, you can then use:

```sh
sudo nft replace rule netsec_tbl netsec_in handle <handle_num> ip saddr 10.10.0.4 icmp type echo-request counter reject
```
where `<handle_num>` is the handle number of your rule.

Now, test the ping from the client again and watch the difference.

## Question sheet

1. Based on the experiment above, what is the main difference between the `drop`
   and the `reject` actions?

2. Consider now the following `nft` script:
    ```sh
    #!/usr/sbin/nft -f

    add table ip netsec_tbl

    add chain netsec_tbl netsec_out { type filter hook output priority 0; }
    ```

    1. Describe the impact of the following rule on the container:
      ```
      add rule netsec_tbl netsec_out icmp type echo-request drop
      ```

    2. Describe the impact of the following rule on the container:
      ```
      add rule netsec_tbl netsec_out icmp type echo-reply drop
      ```

# Your first firewall

Now, we would like to implement our first firewall. The goal of your firewall
is to prevent **all traffic** from the client to the server, expect for the
following TCP ports:

- port 22 for `ssh`,
- port 23 for `telnet`,
- port 80 for `http`.

All other traffic generated by anyone and destined to the server should be
dropped. We are also interested in keeping track of the number of packets that
are able to reach the server, i.e., we do want to count those packets that have
a tcp destination port being one of the above three.

To test your firewall, make sure that all three of the above services are
running:

- To test `ssh`, simply try `ssh server` from the client (you don't need to
  login, just make sure you can connect).
- To test `telnet`, simply try `telnet server` from the client.
- To test `http`, simply try `wget server` from the client. If `wget` is not
  installed on the container, you can install it using `apt update && apt
  install -y wget`.

{:.warning}
All of your firewall rules must be on the firewall container and not the server
itself. We do not want our server to even see any of this traffic.

To test other types of traffic, try to ping the server from the client, you
should not be able to reach the server in any way. Also try to set up a
`netcat` server on the server container and attempt to connect to it from the
client, it should also not work. Here are some examples:

## Test other tcp ports

Create a `netcat` server on the server container using `nc -n -v -l 1234` and
then try to connect to it from the client's side using `nc server 1234`. If
your firewall is configured correctly, it should not make it through.

## Test other protocols

Make sure that `ping` is not working and only TCP services are reachable. To
test out another protocol, set up a UDP `netcat` server on the server using `nc
-n -v -u -l 1234` and then connect to it from the client using `nc -u server
1234`, it should also not be able to connect.

# Submission

Submit your paper question sheet  as well as your `nftables` script for the
final problem via gradescope.

