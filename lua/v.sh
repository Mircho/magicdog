#!/bin/sh
#this is a shell script wrapper for calling the lua program in order to change the context for it into the directory
#it is being executed in. If you find a way to make lua's require when executing a lua script with absolute path
#this can go away
#point at this in nodogsplash conf:
#option binauth '/path/to/directory/v.sh'
cd "$(dirname "$0")"
lua vouchers.lua "$@"
