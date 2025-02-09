---
layout: default
title: Milestone 1
nav_order: 10
has_children: false
last_modified_date: Sun Feb  9 12:15:39 EST 2025
current_term: Winter 2024-25
parent: Project
description: >-
  Description of deliverables for the first milestone
---

# Introduction

The goal of the first milestone is to decide on the network topology and the
network services that are to be running on your network. At the end of this
milestone, you should have your docker container configured, deployed, and
ready to be running any services you'd like them to run.

If your proposed topology is to contain segmented network location, please
indicate what is to be running on each subnetwork and what attack(s) do you
anticipate to be running on each subnet.

# Deliverables

As specified in the high-level description of this project, the deliverables
are split between a report and a repository. Here are the requirements for each
milestone in each case:

1. **For the report**:

  1. An introduction section describing the scope and the aim of the project.

  2. A pictorial representation (ASCII is good for this) of the network
     topology. This topology should reveal the IP addresses of each host on the
     network. If a host has multiple interfaces, it should be clear which
     interface is connected to which subnetwork.

     Please note that using AI tools for this task is perfectly reasonable.
     Describe the network and ask it to generate the image for you. Just please
     make sure to double check that the generated representation makes sense.

  3. If a host or server has special attributes (like does not forward traffic,
     or runs firewall, etc.), please specify those in the list of hosts.

  4. A description of test cases that can be used to verify connectivity
     between hosts on your network. For example, if `hostA` should be able to
     reach `hostB` but not `server`, then please add some verification commands
     after the docker environment is up.

2. **For the repository**:

  1. The `docker_compose` file that contains the network description of your
     network and subnetworks.

  2. A `doc` directory that contains your report in **PDF** or **markdown**
     format.

  3. A `volumes` directory that be shared amongst all containers. All
     configuration files and stater code (if any) should go into this
     repository.

  4. A `readme.md` that contains any instructions specific to building the
     docker environment and deploying it. Please do not replicate your report
     in this document.

# Templates

You can find a starter setup for this project in [this template
repository](https://github.com/rhit-netsos/netsec-docker-template). Feel free
to generate a repository based off of this one, and then modify your access
rights accordingly. Please make sure that your generated repository is
**private** and that you can give me access to it; my GitHub id is `nouredd2`.

