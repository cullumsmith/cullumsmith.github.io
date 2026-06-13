---
title: FreeBSD 15 on a Laptop
date: June 10, 2026
description: A guide to installing FreeBSD on a laptop with KDE 6.
social-image: blog/freebsd-15-on-a-laptop/kde6-small.png
draft: true
---

FreeBSD 15 really feels like a breakthrough release.

It's always been a great operating system for servers, but with the arrival of
[pkgbase](https://wiki.freebsd.org/action/show/pkgbase), massive improvements to the
[LinuxKPI](https://wiki.freebsd.org/LinuxKPI) drivers, and the launch of the [Laptop
Support and Usability Project](https://github.com/FreeBSDFoundation/proj-laptop), it's
becoming quite usable as a primary desktop!

Since [my last attempt](/blog/freebsd-14-on-the-desktop/) with FreeBSD 14, a lot has
changed:

- KDE Plasma 6 was ported
- Wayland is now working
- Intel WiFi gained full support (no more 802.11g!)

There's also a new [Laptop Compatibility
Matrix](https://freebsdfoundation.github.io/freebsd-laptop-testing/) where you can learn
what works on your hardware.

Let's build a FreeBSD laptop system with KDE. This guide will assume you're using Intel
graphics with an Intel wireless chipset.

[![](kde6.png "KDE Plasma 6 on FreeBSD")](kde6.png){.center}

## Installation

## Devices, Drivers, and Tuning

### Bootloader Tunables

### Sysctl Tweaks

### WiFi

### CPU Microcode and Power Savings

### Intel Graphics Driver

### Linux Binary Compatibility

### Sound

### Device Permissions via devfs

### USB Power Saving

### ThinkPad Backlight Controls

### Reboot

## Firewall

## Disable Periodic Scripts

## Add Users

## Set Locale

## Enable NTP

## Set Your Timezone

## Switch to openssh-portable

## Fix 256-color Terminals

## Install Root Certificates

## Install KDE and Desktop Applications

## Install Fonts

## Enable D-Bus

## Configure Ly Login Manager

## Known Issues
