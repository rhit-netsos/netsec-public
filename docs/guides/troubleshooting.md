---
layout: page
title: Troubleshooting
last_modified_date: 2024-12-10 23:04
current_term: Winter 2024-25
parent: Guides
nav_order: 70
description: >-
  Troubleshooting tips collected here.
---

## Table of contents
{:.no_toc}

1. TOC
{:toc}

---

# Cannot find `sudo` on the container

If you try to run the `sudo` command and you get an error message telling you
the `sudo` cannot be found, your docker service might be running on a cached
stale version of the class container.

To fix this, you will need to remove the container image to the most up to date
one can be re-downloaded. First, check out which images you have by issuing the
following command on your virtual machine:

```sh
docker image ls
```

Mine looks like the following:

```
REPOSITORY                       TAG       IMAGE ID       CREATED         SIZE
netsos/rhit-netsec               latest    eb20fb69f1db   7 days ago      1.37GB
netsos/rhit-netsec               <none>    0f6dc5fc9299   8 days ago      1.37GB
netsos/rhit-netsec               <none>    2bb2197881ab   8 days ago      1.36GB
kalilinux/kali-rolling           latest    9fbb6aad6757   10 days ago     129MB
openvpn/openvpn-as               latest    7268bba0967e   8 months ago    674MB
p4lang/p4c                       latest    4a81a016ebb4   10 months ago   1.77GB
netsos/rhit-netsec               fw        b559df8e262f   10 months ago   976MB
netsos/rhit-netsec               base      aacc8a3a9a4b   10 months ago   927MB
netsos/rhit-netsec               tcplab    cf08e1097c02   11 months ago   1.56GB
netsos/rhit-netsec               <none>    f8e3d779c096   11 months ago   1.54GB
hello-world                      latest    d2c94e258dcb   19 months ago   13.3kB
linuxserver/openvpn-as           latest    7a4f12e2c18d   3 years ago     228MB
ghcr.io/linuxserver/openvpn-as   latest    7a4f12e2c18d   3 years ago     228MB
```

The one that matters the most here is the following:

```
netsos/rhit-netsec               latest    eb20fb69f1db   7 days ago      1.37GB
```

So now you can delete this image as follows:

```shell
docker image rm netsos/rhit-netsec:latest
```

Note that you can use the `<tab>` key to have your shell autocomplete the name
of the container image for you.

{:.highlight}
If you get an error message telling you that the image is in use, then you
have one or more container dangling from one of your experiments. Please bring
those down by navigating to that lab's directory and running `dcdn` in there.

