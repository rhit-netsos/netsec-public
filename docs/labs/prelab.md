---
layout: page
title: Prelab
last_modified_date: 2024-12-03 12:24
current_term: Winter 2024-25
nav_order: 1
parent: Labs
description: >-
  Setup and docker guide to create labs.
---

## Table of contents
{:.no_toc}

1. TOC
{:toc}

---

# Prelab

In this prelab, we will get started with setting things up to spin up a virtual
network using Docker, and accessing the machines on it.

## Login to the server

If you will be using our class server, then login using `ssh`. If you have set
things up correctly, you should be able to just use `ssh netsec`.

## Test access to Docker

To make sure the server has been appropriately configured, please try to run the
docker hello world instance. To do so, use:

  ```shell
  $ docker run hello-world

  Hello from Docker!
  This message shows that your installation appears to be working correctly.

  To generate this message, Docker took the following steps:
   1. The Docker client contacted the Docker daemon.
   2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
      (amd64)
   3. The Docker daemon created a new container from that image which runs the
      executable that produces the output you are currently reading.
   4. The Docker daemon streamed that output to the Docker client, which
      sent it to your terminal.

  To try something more ambitious, you can run an Ubuntu container with:
   $ docker run -it ubuntu bash

  Share images, automate workflows, and more with a free Docker ID:
   https://hub.docker.com/

  For more examples and ideas, visit:
   https://docs.docker.com/get-started/
  ```

If you do not see the message above, then please contact me as soon as possible
so I can take a look.

## Get the lab

For this lab, we will be using GitHub classroom to get the starter code. Please
follow this [link](https://moodle.rose-hulman.edu/mod/url/view.php?id=4742081)
to accept the assignment and obtain your own fork of the lab repository.

{: .important }
The first time you accept an invite, you will be asked to link your account to
your student email and name. Please be careful and choose your appropriate
name/email combination so that I can grade appropriately.


# Generating your `.env` file

Before we spin up our containers, there are some configuration variables that
must be generated on the spot. To do so, please run the `gen_env_file.sh`
script from the prelab repository directory as follows:

  ```shell
  $ ./gen_env_file.sh
  ```

If run correctly, three files will be generated:

1. `.env` (hidden file - use `ls -al` to see it) contains your UID and GID
   variables.

2. `connect_hostA.sh` a utility script to quickly connect to `hostA`.

3. `connect_hostB.sh` a utility script to quickly connect to `hostB`.

# Spin up the containers

Now you are ready to spin up the containers for this prelab. In the prelab
repository direcotyr, spin up the environment using:

  ```shell
  $ docker compose up -d
  ...
  [+] Running 3/3
   ✔ Network local-net  Created          0.1s
   ✔ Container hostB    Started          0.1s
   ✔ Container hostA    Started          0.1s
  ```

Alternatively, you can also use `dcupd` as an alias to `docker compose up -d`.

If you see the output, your environment is fully setup and are running. If you
run into any issues, then please contact me as soon as possible.

{:.highlight}
The fist time you run the environment, it needs to download the virtual machine
images, so it might take a while. After that, it should be faster, unless
occasionally when I patch the image.

## Check your images

First, check on your environment using:

  ```shell
  $ docker compose ls
  NAME                STATUS              CONFIG FILES
  prelab              running(2)          <removed for privacy>
  ```

If things look good, check on your running containers as follows:

```shell
$ docker compose ps
NAME         IMAGE                       COMMAND                                                          SERVICE      CREATED         STATUS         PORTS
hostA   netsos/rhit-netsec:latest   "bash -c 'bash /volumes/check_config.sh && tail -f /dev/null'"   hostA   4 minutes ago   Up 4 minutes
hostB   netsos/rhit-netsec:latest   "bash -c 'bash /volumes/check_config.sh && tail -f /dev/null'"   hostB   4 minutes ago   Up 4 minutes
```

If all looks good, move on to the next step.

# Access the containers

Next, let's ssh into one of the containers to make sure things are okay. In your
`prelab` directory, use the following:

  ```shell
  $ ./connect_hostA.sh
  ```

This will drop you into a shell on the `hostA` container. **You will be
logged in as the user `netsec`**, but you have passwordless `sudo` privileges
on the container.

Try the same on `hostB` to make sure that it is up as well.

## Shared volumes

In this `prelab` directory, you will notice that there is a `volumes/`
directory. Once you spin up your containers, this directory will mounted by your
containers, i.e., it will be shared between your host machine and the
containers. Any changes the containers make to the directory will impact the
`volumes/` directory under `prelab/`.

Test this out. On your host server (i.e., on the class server), add a dummy file
to the `volumes/` directory.

  ```shell
  $ echo "Hello World" > volumes/test.txt
  ```

Then, access any one of the containers and try to read the file:

  ```shell
  $ cat /volumes/test.txt
  Hello World
  ```

{:.highlight}
Note that in the containers, that directory is mounted under `/volumes`.

{:.highlight}
You will mostly use the `volumes/` directory to compile your code and push it
onto the containers for testing. You will also be using it to collect network
packet data from your running containers.

# Test networking

Now on to the most relevant parts of this. Let's make sure that our network has
been set up correctly.

## Checking on hostA

Login to the `hostA` container as we have showed above. Then from there,
check your network interfaces and network configuration:

  ```shell
  (hostA) $ ip a
  1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
      link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
      inet 127.0.0.1/8 scope host lo
          valid_lft forever preferred_lft forever
  223: eth0@if224: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
      link/ether 02:42:0a:0b:01:04 brd ff:ff:ff:ff:ff:ff link-netnsid 0
      inet 10.11.1.4/24 brd 10.11.1.255 scope global eth0
          valid_lft forever preferred_lft forever
  ```

You can see that the container has two interfaces:

1. `lo`: This is the loopback interface. By default, it's ip address is
   `127.0.0.1`.

2. `eth0`: This is the virtual NIC connected to your subnet. Notice its ip
   address, it is `10.11.1.4`.

   {:.warning}
   Your IP address might be different from mine depending on your container
   configuration. That is totally ok. Replace all values with the corresponding
   ones obtained from the command or from peeking into the Docker compose file.

## Reaching hostB

From `hostA`, try to ping `hostB` to make sure that the route it setup. To do
so, use:

  ```shell
  (hostA) $ ping -c1 hostB
  PING hostB (10.11.1.5) 56(84) bytes of data.
  64 bytes from hostB.local-net (10.11.1.5): icmp_seq=1 ttl=64 time=0.071 ms

  --- hostB ping statistics ---
  1 packets transmitted, 1 received, 0% packet loss, time 0ms
  rtt min/avg/max/mdev = 0.071/0.071/0.071/0.000 ms
  ```

Note that you can also reach `hostB` using its ip address as follows:

  ```shell
  (hostA) $ ping -c1 10.11.1.5
  ```

Make sure to adjust the IP address to the value you see in the `ping` command
above or the Docker compose file you have on hand.

## Bi-directional communication

Next, let's make sure we can communicate both ways between A and B. You will
need to flex your `tmux` muscles here.

Launch a `tmux` session in the `prelab` directory, then split it into two panes
(horizontally or vertically, depending on your preference).

Then in one pane, login to `hostA`, while on the other pane, login
`hostB`. We will make `hostA` our server while `hostB` will be
our client.

On `hostA`, user:
  ```shell
  (hostA) $ suod apt install -y netcat-openbsd
  (hostA) $ nc -l 1234
  ```
This will start a `netcat` TCP server running on port 1234.

One `hostB`, connect to that server as follows:
  ```shell
  (hostB) $ sudo apt install -y netcat-openbsd
  (hostB) $ nc hostA 1234
  ```

Now, anything you type on `hostB` will show on the screen under
`hostA`.

To close the connection on `hostB`, simply hit `C-c` (recall, this means
`ctrl` and c). This will close on both ends.

## Talking to the outside world

Finally, let's make sure that you can reach the outside world (we're not always
going to have that option open, but it is for now). Let's see how your route to
`1.1.1.1` looks like. To do so, on either container, do the following:

```shell
(hostA) $ traceroute 1.1.1.1
traceroute to 1.1.1.1 (1.1.1.1), 30 hops max, 60 byte packets
 1  10.11.1.1 (10.11.1.1)  0.048 ms  0.017 ms  0.012 ms
 2  137.112.104.3 (137.112.104.3)  0.398 ms  0.458 ms  0.467 ms
 3  137.112.9.156 (137.112.9.156)  0.118 ms  0.103 ms  0.104 ms
 4  * * *
 5  199.8.48.102 (199.8.48.102)  2.026 ms  2.049 ms  2.014 ms
 6  ae-0.2022.rtr.ll.indiana.gigapop.net (199.8.220.1)  1.976 ms  2.757 ms  2.772 ms
 7  206.53.139.34 (206.53.139.34)  2.963 ms  2.568 ms  2.902 ms
 8  one.one.one.one (1.1.1.1)  3.487 ms  3.501 ms  3.378 ms

```

# Take down your containers

Once you are done, shut down your containers using:

  ```shell
  $ docker compose down
  ```

Alternatively, you can also use `dcdn` as an alias.

After a while, the containers should be down and the network will be removed.

{:.warning}
Please note that the containers are ephemeral; anything you install or change in
the container will be lost after shutting it down. If you need files to persist
beyond the lifetime of a container, then write them to `/volumes/`.

{:.warning}
If you are not actively working on this class, please do take down your docker
environments, to make room for other students in the class.


