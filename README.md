<!--
********************************************************************************
* Copyright (C) 2017-2020 German Aerospace Center (DLR). 
* Eclipse ADORe, Automated Driving Open Research https://eclipse.org/adore
*
* This program and the accompanying materials are made available under the 
* terms of the Eclipse Public License 2.0 which is available at
* http://www.eclipse.org/legal/epl-2.0.
*
* SPDX-License-Identifier: EPL-2.0 
********************************************************************************
-->
# PlotLab is yet another plotting tool...
* [lib](lib) contains a client library to send plot commands to a plot (server)[server].
* [server](server) contains a stand-alone, system-independent c++/OpenGL application, which controls several plot windows and receives plot commands from clients.
* [libzmq](libzmq) contains docker file to build libzmq.

## Requirements
* docker
* make

## Building

clone project:
```sh
git clone --recurse-submodules git@gitlab.dlr.de:csa/plotlab.git
```
or if you have already cloned the project:
```sh
git submodules init
git submodules update
```

* if you do not clone with --recurse-submodules make will fail.

run: 
```sh
make
```

## Artifacts

all artifacts will be in lib/build, server/build, and libzmq/build
