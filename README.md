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

* [plotlabserver](plotlabserver) contains a stand-alone, system-independent c++/OpenGL application, which controls several plot windows and receives plot commands from clients.

This project provides a docker context to build and run plotlabserver.

## Build Status
[![CI](https://github.com/DLR-TS/plotlabserver/actions/workflows/ci.yaml/badge.svg)](https://github.com/DLR-TS/plotlabserver/actions/workflows/ci.yaml)

## Requirements
* docker
* make

## Getting Started

clone project:
```sh
git clone --recurse-submodules -j8 git@github.com:DLR-TS/plotlabserver.git
```
or if you have already cloned the project:
```sh
cd plotlabserver
git submodules init
git submodules update
```

* if you do not clone with --recurse-submodules make will fail.

To view help for available make targets run the default target:
```bash
make
```

To build and run plotlabserver run the provide "up" target: 
```sh
make up
```

## Display Modes
The provided docker context supports three display modes: native, window_manager, headless.
To change the display mode modify the DISPLAY_MODE environmental variable in the docker-compose.yaml

### Setting a display mode

There are two options for setting a display mode. You can modify the docker-compose.yaml
```yaml
...
    environment:
      - DISPLAY_MODE=${DISPLAY_MODE:-native}
      # - DISPLAY_MODE=${DISPLAY_MODE:-window_manager}
      #- DISPLAY_MODE=${DISPLAY_MODE:-headless}
...
```
Uncomment the desired display mode.

You can also directly set the environmental variable before calling "make up":
```bash
DISPLAY_MODE=native make up
```
or 
```bash
DISPLAY_MODE=window_manager make up
```
or
```bash
DISPLAY_MODE=headless make up
```

#### Display Mode: native
plotlabserver windows will be displayed as native windows within the host system window manager (does not support video recording)

#### Display Mode: window_manager
plotlabserver windows will be displaced within a nested i3 window manager (supports video recording)

#### Display Mode: headless
plotlabserver windows will be displayed on a virtual xvfb display suitable for headless host systems (supports video recording)

## Display Recording
The docker context provides built in display recording via ffmpeg.  This is supported in window_manager and headless 
display modes. One display recording is kept at a time.  Triggering a new scenario will result in the previous 
recording to be overwritten.


## Artifacts

All build artifacts will be available at plotlabserver/build including the 
plotlabserver binary.
