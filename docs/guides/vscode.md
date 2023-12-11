---
layout: page
title: VSCode Setup
last_modified_date: Mon Dec 11 12:59:27 2023 
current_term: Winter 2023-24
nav_order: 70
parent: Guides
description: >-
  Setting up VSCode for libpcap development.
---

## Table of contents
{:.no_toc}

1. TOC
{:toc}

---

# Introduction

This guide will help you set up your remote VSCode instance to connect to the
class server, and then adjust it so that you can use to develop with `libpcap`.
Code completion features should be working at the end of this tutorial.

# The setup

To help out with coding in C with `libpcap`, I have figured out a way to
configure VSCode's IntelliSense to grab definitions and symbols for the
networking header files, which would be helpful for you in developing the files.

First, install the `Visual Studio Code Remote - SSH` extension in your local
VSCode instance. You can find it by searching for `ssh` in your extensions
marketplace, it will show up right towards the top.

Then, follow the instructions in the section `Connect to a remote host` in the
VSCode [documentation](https://code.visualstudio.com/docs/remote/ssh).

Once the window loads (it will ask a few questions and might prompt you for your
password if you have not set up your keys yet), open a new folder, and navigate
to the root of your labs repository. Once it loads, you should your usual file
navigator on the left-hand side and you can open any of your files.

If you open any of the `.c` file, VSCode will go frantic and give you so many
errors; we need a few configurations yet.

First, install the `C/C++` and `C/C++ Extension` packs from the VSCode extension
marketplace (simply look them up and hit install) and then reload your window.

Second, create a new folder in the root of your repo (i.e., in
`netsec-labs-username`) and call it `.vscode` (the `.` is necessary). In that
directory, create a new file called `c_cpp_properties.json` and dump the
following in it:

  ```json
  {
    "configurations": [
        {
            "name": "Linux",
            "includePath": [
                "${workspaceFolder}/**",
                "/usr/include",
                "/usr/include/**",
                "${workspaceFolder}/lab2/volumes/src/nslib"
            ],
            "compilerPath": "/usr/bin/gcc",
            "cStandard": "c99",
            "intelliSenseMode": "linux-gcc-x64",
            "mergeConfigurations": true,
            "defines": [
              "_GNU_SOURCE",
              "__USE_MISC"
            ],
            "browse": {
              "path": [
                "/usr/include",
                "/usr/include/**",
                "${workspaceFolder}"
              ],
              "limitSymbolsToIncludedHeaders": true,
              "databaseFilename": "${workspaceFolder}/.vscode/browse.vc.db"
            }
        }
    ],
    "version": 4
  }
  ```

After that, give your `.c` files a moment to reload, and all the errors should
disappear. You should also be able to get code completion and all the perks.

