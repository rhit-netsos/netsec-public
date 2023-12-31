---
layout: page
title: Prelab
last_modified_date: Tue 28 Nov 2023 12:25:46 PM EST
current_term: Winter 2023-24
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

In your labs repository, get the latest updates from the class repo as follows:

First, make sure all you changes have been committed and pushed to your private
repository. Follow the standard `git add`, `git commit -m`, and `git push`
process.

If your `git push` asks you to choose a destination, then use `origin main` as
follows:
  ```shell
  $ git push origin main
  ```

Then, fetch and merge the changes from the class repository as follows:

  ```shell
  $ git fetch upstream
  $ git pull upstream main
  $ git push origin main
  ```

You should have a directory called `prelab` in your repository and you are good
to go.

# Patching your lab

To make sure that your network are isolated, we need to set you up on different
subnetworks and with different hostnames.

## Note your subnet

Each student will have a subnet allocated to them, that supports up to 32
addresses (including broadcast and defaults). For your privacy, I will not post
the mappings here. Instead, you will find them on the class Moodle page. Here's
a [direct link](https://moodle.rose-hulman.edu/mod/resource/view.php?id=4207543)
to the csv file for your convenience.

Locate your username in the csv file and write down your subnet. It should look
something like `10.10.1`. In what follows, I will assume that we are dealing
with subnet `10.11.1`.

## Patch the lab

In the `prelab` directory, run the script to patch the `docker-compose.yml` file
as follows:

  ```shell
  ./patch_docker_compose.sh user 10.11.1
  Done.....
  ```

`user` is your username (or any unique identifier for yourself) and `10.11.1` is
your subnet from above.

### Verify patch

Verify that your docker compose file now looks something like below:

```docker
version: '3'

services:
  # Add your services here, default image is netsos/rhit-netsec:latest
  #
  # Make sure to sync volumes using the following.
  # volumes:
  #   - ./volumes:/volumes
  #
  # Run the config script.
  # command:
  #   bash -c "bash /volmes/check_config.sh && tail -f /dev/null"
  #
  user-hostA:
    image: netsos/rhit-netsec:latest
    container_name: user-hostA
    tty: true
    cap_add:
      - ALL
    volumes:
      - ./volumes:/volumes
    networks:
      user-local-net:
        ipv4_address: 10.11.1.4
    command:
      bash -c "bash /volumes/check_config.sh && tail -f /dev/null"

  user-hostB:
    image: netsos/rhit-netsec:latest
    container_name: user-hostB
    tty: true
    cap_add:
      - ALL
    volumes:
      - ./volumes:/volumes
    networks:
      user-local-net:
        ipv4_address: 10.11.1.5
    command:
      bash -c "bash /volumes/check_config.sh && tail -f /dev/null"

networks:
  user-local-net:
    name: user-local-net
    # enable this if need the network isolated without Internet access.
    # internal: true
    ipam:
      config:
        - subnet: 10.11.1.0/24
```

# Spin up the containers

Now you are ready to spin up the containers for this prelab. In the `prelab/`
directory, spin up the environment using:

  ```shell
  $ docker compose up -d
  ...
  [+] Running 3/3
   ✔ Network user-local-net  Created          0.1s
   ✔ Container user-hostB    Started          0.1s
   ✔ Container user-hostA    Started          0.1s
  ```

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
user-hostA   netsos/rhit-netsec:latest   "bash -c 'bash /volumes/check_config.sh && tail -f /dev/null'"   user-hostA   4 minutes ago   Up 4 minutes
user-hostB   netsos/rhit-netsec:latest   "bash -c 'bash /volumes/check_config.sh && tail -f /dev/null'"   user-hostB   4 minutes ago   Up 4 minutes
```

If all looks good, move on to the next step.

# Access the containers

Next, let's ssh into one of the containers to make sure things are okay. In your
`prelab` directory, use the following:

  ```shell
  $ docker container exec -it user-hostA /bin/bash
  ```

This will drop you into a shell on the `user-hostA` container. **You will be
logged in as root** so be careful in what you are doing. However, everything you
do will only impact your container!

Try the same on `user-hostB` to make sure that it is up as well.

## Shared volumes

In this `prelab` directory, you will notice that there is a `volumes/`
directory. Once you spin up your containers, this directory will mounted by your
containers, i.e., it will be shared between your host machine and the
containers. Any changes the containers make to the directory will impact the
`volumes/` directory under `prelab/`.

Test this out. On your host server (i.e., on the class server), add a dummy file
to the `volumes/` directory.

  ```shell
  $ echo "Hello World!" > volumes/test.txt
  ```

Then, access any one of the containers and try to read the file:

  ```shell
  $ cat /volumes/test.txt
  Hello World!
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

Login to the `user-hostA` container as we have showed above. Then from there,
check your network interfaces and network configuration:

  ```shell
  (user-hostA) $ ip a
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

## Reaching hostB

From `user-hostA`, try to ping `user-hostB` to make sure that the route it
setup. To do so, use:

  ```shell
  (user-hostA) $ ping -c1 user-hostB
  PING user-hostB (10.11.1.5) 56(84) bytes of data.
  64 bytes from user-hostB.user-local-net (10.11.1.5): icmp_seq=1 ttl=64 time=0.071 ms

  --- user-hostB ping statistics ---
  1 packets transmitted, 1 received, 0% packet loss, time 0ms
  rtt min/avg/max/mdev = 0.071/0.071/0.071/0.000 ms
  ```

Note that you can also reach `user-hostB` using its ip address as follows:

  ```shell
  (user-hostA) $ ping -c1 10.11.1.5
  ```

## Bi-directional communication

Next, let's make sure we can communicate both ways between A and B. You will
need to flex your `tmux` muscles here.

Launch a `tmux` session in the `prelab` directory, then split it into two panes
(horizontally or vertically, depending on your preference).

Then in one pane, login to `user-hostA`, while on the other pane, login
`user-hostB`. We will make `user-hostA` our server while `user-hostB` will be
our client.

On `user-hostA`, user:
  ```shell
  (user-hostA) $ apt install -y netcat-openbsd
  (user-hostA) $ nc -l 1234
  ```
This will start a `netcat` TCP server running on port 1234.

One `user-hostB`, connect to that server as follows:
  ```shell
  (user-hostB) $ apt install -y netcat-openbsd
  (user-hostB) $ nc user-hostA 1234
  ```

Now, anything you type on `user-hostB` will show on the screen under
`user-hostA`.

To close the connection on `user-hostB`, simply hit `C-c` (recall, this means
`ctrl` and c). This will close on both ends.

## Talking to the outside world

Finally, let's make sure that you can reach the outside world (we're not always
going to have that option open, but it is for now). Let's see how your route to
`1.1.1.1` looks like. To do so, on either container, do the following:

```shell
(user-hostA) $ traceroute 1.1.1.1
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

After a while, the containers should be down and the network will be removed.

{:.warning}
Please note that the containers are ephemeral; anything you install or change in
the container will be lost after shutting it down. If you need files to persist
beyond the lifetime of a container, then write them to `/volumes/`.

{:.warning}
If you are not actively working on this class, please do take down your docker
environments, to make room for other students in the class.


