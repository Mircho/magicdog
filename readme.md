# MagicDog (Вълшебно куче) NoDogSplash Token Access

As the stay at home of 2020 progressed I had to devise a way to incetivize my kids to do the chores and homeworks without getting into creative discussions about "overusing" tiktok and youtube. So I wanted to be able to issue some kind of convertible currency that is exchanged for doing their homework. The acceptable payment would be internet time.

Thus the technical solution to the problem - MagicDog Lua implementation of the binauth endpoint of NoDogSplash for OpenWrt.

## Requirements:

- To provide "special" wifi AP, that will take "internet tokens" as payment for enabling access
- Those tokens belong to the bearer and each has time period for internet access as "value" (potential for kids to form their internal exchange)
- There should be several tiers of tokens - 15, 30, 60 minutes (etc.) 
- It should be implemeted in some scripted language development to happen on a Linux box, but finally run on the router.

## Solution

The result is a module that works utilizes [NoDogSplash](https://github.com/nodogsplash/nodogsplash) binauth functionality to authenticate users.

There are two things to be done in order to make it work on your OpenWrt router.
- Copy the contents of the lua directory into a directory on your router. As it needs to read and write from a sqlite DB and create logs I suggest to have it on an external flash drive to minimize flash writes.
- Copy the contents of the web/splash/build directory to a directory on your router and point NDS to it (see more in the respective readme)

## Setting up the router

- Follow the instructions on the [guest network on a dumb AP](https://openwrt.org/docs/guide-user/network/wifi/guestwifi/guestwifi_dumbap)
- Install NDS from with opkg. Tested with 19.07 and NDS 4
