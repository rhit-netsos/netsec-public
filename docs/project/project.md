---
layout: default
title: Project
nav_order: 7
has_children: true
parmalink: docs/project/
---

# Introduction

In this project, you will design, deploy, and analyze your own a small-scale
network security laboratory assignment. You will select a simple topology and
deploy it using `docker` containers. You will then configure some vulnerable
services in this network and guide your disciples through the steps of
identifying those vulnerabilities and exploiting them. By learning these
concepts and them writing them in a way aimed at teaching them to others, you
will gain a deeper understanding of network services, how they work, how they
fail, and how they can be hardened.

# Learning Objectives

At the end of this lab, you should be able to:

1. Design a simple network and deploy it using `docker` containers.

2. Deploy sample services (such as DNS, OpenVPN, FTP, etc.) and configure them.

3. Identify vulnerabilities in networked services and set up an environment to
   exploit them.

4. Write a guide for your fellow students to guide them through your lab and
   challenge them to do it!

# Deliverables

This project is split into three milestones distributed over the course of
three weeks. At the end of the third week, you should present the following:

1. A detailed report that includes the following:

    1. A description of your network topology, its sub-networks, its hosts, and
       their IPv4 address assignments.

    2. A description of each host and the services running on it. You should also
       indicate if that host is benign or malicious.

    3. In case of a malicious host, you should specify **exactly** what
       privileges this host enjoys.

    4. Step-by-step instructions that will guide a practitioner or students
       through your network. You should create experiments in which the student
       can capture traffic to observe the network's behavior and understand the
       scenario in detail.

    5. A description of the possible vulnerabilities in the network along with
       instructions to develop and observe an exploit.

       For any exploit you focus on, your report should include specific
       **success criteria** that the student can use to evaluate their approach.

2. A `GitHub` repository that contains the following:

    1. A `docker_compose` file that can be used to launch the containers for your
       experiment.

    2. A `doc` directory that contains your report in **PDF** or **markdown**
       format. Please do not leave `.docx` files in there.

    3. A `volumes` directory that will be shared with your containers. You should
       add any configuration scripts here.

    4. A `volumes/src` directory that contains any starter source code (and
       solutions) needed to test your lab and later on exploit your setup.

    5. A `readme.md` file that contains a quick summary of your lab along with
       getting started instructions.


# Milestones

{: .no_toc }

