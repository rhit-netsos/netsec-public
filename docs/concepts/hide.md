---
layout: page
title: Hiding a network service
last_modified_date: 2024-02-12
current_term: Winter 2023-24
nav_order: 80
parent: Concepts
lab_dir: hide
description: >-
  Introduction to service isolation
---

## Table of contents
{:.no_toc}

1. no_toc
{:toc}

---

# Introduction

In lab 4, we established a port knocking sequence that allowed us to ask client
to know a certain secret sequence of ports that they must hit before being
allowed to access a given port. However, the problem with that is we have no
way to autenticate however knows the port sequence is actually someone we can
trust; they might have beaten the sequence out of someone we know, and now they
can access our hidden service. Furthermore, once our sequence is compromised,
changing that sequence and letting everyone know becomes a problem.

Therefore port knocking without authentication is an issue that we must
address. In this concept lab, we will examine one possible way to hide services
by using other autenticated services.

# Learning objectives

At the end of this lab, you should be able to:

- Examine a way to hide a web service behind a firewall while only allowing
  authenticated services through it.

# Logistics

## Getting the configuration

To start with this lab, login to the class server, and navigate to your
`netsec-labs-username` directory. Grab the latest updates using:

  ```shell
  (class-server) $ git fetch upstream
  (class-server) $ git pull upstream main
  ```

A folder called `{{ page.lab_dir }}` should show up in your directory, that is
where you will do most of your lab.

## Patching the docker file

{:.warning}
Before starting here, please make sure that your experiments from all other
labs are down.  To do so, navigate back to the latest lab directory and do
`docker compose down`.

I have updated the patch script to no longer ask you for your username and
subnet, it will try to extract those on its own and print out your subnet (it
is the same on as the one announced on the Moodle page). Also, it now generates
scripts for you to connect to your hosts quickly.

To do so, in the `{{ page.lab_dir }}` directory, run the patch script:

  ```sh
  (class-server) $ ./patch_docker_compose.sh
  Attempting to fetch subnet automatically...
  Found your subnet, it is 10.10
  Done...
  ```

If you had already patched your script, you will see something like this:

  ```sh
  (class-server) $ ./patch_docker_compose.sh
  Attempting to fetch subnet automatically...
  Found your subnet, it is 10.10
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

If all goes well, you should also see two new files in your directory:
`connect_client.sh` and `connect_server.sh`. You can use these scripts to
directly connect to the desired host, without having to type the whole `docker
container exec -it` command. Finally, I have also adjust the container's
hostnames to make it easier for you to identify which is which.

For example, to connect to `client`, you can use:

  ```sh
$ ./connect_client.sh
┌──(root㉿client)-[/]
└─#
  ```

Hopefully, that would make things a bit easier for you.

{:.highlight}
If you are unable to execute a script due to a permissions issue, then try the
following `$ chmod +x <script name.sh>` to make it executable and try again.

{:.warning}
In the remainder of this document, I will not be using your specific prefixes
and subnets. For example, when I refer to `client`, you should replace that with
`user-client` where `user` is your RHIT username. Similarly, I will be using
`10.10.0` as the default subnet, you should replace that in all IP addresses
with your own subnet. For example, if your subnet is `10.11.0`, then replace the
IP address `10.10.0.1` with `10.11.0.1`.

# Network topology

In this lab, we have a web server protected by a firewall and a client sitting
on a different subnet trying to reach the server.

 ```
                                                       | ----------- |
                                              -------- | Workstation |
                                              |        | ----------- |
                                              |
 | ------ |                | -------- |       |        | ------ |
 | Browser| -------------- | Firewall | -------------- | Server |
 | ------ |  10.10.0.0/24  | -------- |  10.10.1.0/24  | ------ |
 ```

---
