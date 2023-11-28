---
layout: home
title: "CSSE 490: Network Security"
nav_exclude: true
permalink: /:path/
seo:
  type: Course
  name: Network Security
---

# Introduction to Network Security
## Rose-Hulman Institute of Technology, Winter 2023-24

Welcome to CSSE490: Introduction to Network Security at RHIT!

![virus_farm](https://imgs.xkcd.com/comics/network.png)

This course serves as an introduction to the basic concepts of network security
with an emphasis on practical and development skills. Topics include denial of
service attacks and defenses, authentication, key distribution, message
authentication, access control, protocol security, virtual private networks, and
security standards.  The course will provide a review of basic network design,
the end-to-end principle, and basic cryptography. Prerequisites: CSSE 220 or
approval of the instructor.

Before class starts, please familiarize yourself with this website, including
the different menus on the left-hand pane. This is the source of all
authoritative announcements for the class, if this page and what I say in class
contradict each other, please follow what is on this webpage.

### Before the first class

Before our first class, please read the [syllabus](syllabus) and get to know your
[instructor]({{ site.baseurl }}/staff). This class is mostly built on labs that
you will be doing during class meeting times, therefore it is important that you
come to the first day prepared with a good development environment.

Therefore, I do recommend that you follow the steps below to get started strong
on day 1:

1. __Terminal Emulator__<br>
    Get yourself a good terminal emulator, preferably running on a Unix-based
    distribution. Follow the steps in the [tutorials](docs/guides/guides) page
    to set yourself up with one.
2. __Terminal skills__<br>
    For this class to work out, you will need to be comfortable with a terminal
    window. There are plenty of tutorials out there to help you out, but
    essential skills like navigating directories, copying and moving files,
    `grep`, and compiling and running programs are crucial for your success.
3. __Version Control__<br>
    Create an __empty private__ repository (anywhere you prefer, most use
    [Github](https://github.com)). Follow the steps in the
    [tutorials](docs/guides/guides) page to get the content of the first lab and
    test connectivity.
4. __Connectivity__<br>
    Throughout the class, we will be working on dedicated machines that would
    allow us to run risky experiments. Follow the steps in the
    [tutorials](docs/guides/guides) page to make sure you can access your
    assigned virtual machine, and make sure that you can `ssh` into it.
5. __tmux__<br>
    It is in the nature of networking labs that you will be working across two
    or more machines (containers in our case). Therefore, it is crucial that you
    can switch between them easily. I strongly recommend that you take a moment
    to familiarize yourself with `tmux` and check out my provided configuration
    file on the [tutorials](docs/guides/guides) page.
6. __Coding__<br>
    Most of your coding will be done on the remote machines you are assigned.
    Those machines already have `vim` and `emacs` preintalled. You can check out
    my config file for `vim` in the [tutorials](docs/guides/guides) page. You
    can also hook up `vscode` to connect remotely to your machine if you prefer
    to use an IDE. I will leave that one up to you to figure out if you elect to
    do so.
7. __Enjoy__<br>
    Enjoy the class and please give me feedback as we move along the quarter!

