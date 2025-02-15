---
layout: default
title: Milestone 2
nav_order: 20
has_children: false
last_modified_date: Sat Feb 15 07:31:08 EST 2025
current_term: Winter 2024-25
parent: Project
description: >-
  Description of deliverables for the second and last milestone
---

# Introduction

For the second milestone of this project, you should have your network topology
already configured and set up, and it is time to write and test your exploit or
potential exploration. Make sure that any services that your containers need to
run are already configured in a stable manner. In other words, if you have a
container that runs a web server, make sure that the server is configured to
start at boot time, rather than requiring you to configure it after the
container has been set up.

# The Exploit

Your exploit should be dependent on the network topology and the services
running in your network. Please break down your exploit into steps that you
describe in detail as part of your report. For each step, make sure to grab a
packet capture that you can use to describe and document your exploit and
services.

If your exploit requires writing source code, then please make sure to document
your code and describe it in the report.

# Deliverables

As specified in the high-level description of this project, the deliverables
are split between a report and a repository. Here are the requirements for this
milestone in each case:

## Project report

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

5. **New**: A description of the steps involved in creating the exploit. Please
   provide as much as detail as you think needed for a student who is just
   starting this project to be able to reproduce your results.

6. **New**: A detailed description of the success criteria to be used for the
   exploit. Make sure to include snapshots and/or output samples for each case.

7. **New**: (If applicable) Include a set of leading questions that can be used
   by a student to understand your setup and design an exploit.

## Project repository

1. The `docker_compose` file that contains the network description of your
   network and subnetworks.

2. A `doc` directory that contains your report in **PDF** or **markdown**
   format.

3. A `volumes` directory that be shared among all containers. All
   configuration files and stater code (if any) should go into this
   repository.

   - A `volumes/src` directory that contains any source code need to run the
     exploit or examine the network. Feel free to split that directory between
     `code` and `solution.`

   - If you need to use the `C` library that I have developed for the earlier
     labs, please feel free to grab from lab 2 and adjust the `makefile`
     accordingly.

4. A `readme.md` that contains any instructions specific to building the
   docker environment and deploying it. Please do not replicate your report
   in this document.

5. A `cap` directory that contains any packet captures that are need to
   understand the behavior of your network as well as reproduce the exploit.

# Submission

Please `zip` up all of your necessary files and submit them through Gradescope.

