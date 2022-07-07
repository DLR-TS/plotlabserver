#!/usr/bin/env bash


xhost +si:localuser:$( whoami ) >&/dev/null && { 
    echo "GUI"
} || {
   echo "console"
}
