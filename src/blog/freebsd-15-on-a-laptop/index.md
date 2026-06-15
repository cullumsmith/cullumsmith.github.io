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
become my primary desktop.

Since [my last attempt](/blog/freebsd-14-on-the-desktop/) with FreeBSD 14, a lot has
changed:

- KDE Plasma 6 was ported
- Wayland is now working
- Intel WiFi gained full support (no more 802.11g!)

I'm using a ThinkPad X1 Carbon, but there's also a new [Laptop Compatibility
Matrix](https://freebsdfoundation.github.io/freebsd-laptop-testing/) where you can see
what's working on your hardware.

Let's build a FreeBSD laptop system with KDE! This guide will assume you're using Intel
graphics with an Intel wireless chipset

[![](kde6.png "KDE Plasma 6 on FreeBSD")](kde6.png){.center}

## Installation

Grab a [FreeBSD 15.1 memstick
image](https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/15.1/FreeBSD-15.1-RELEASE-amd64-memstick.img)
and `dd` it to a USB stick:

```bash
curl -OJ https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/15.1/FreeBSD-15.1-RELEASE-amd64-memstick.img
sudo dd if=FreeBSD-15.1-RELEASE-amd64-memstick.img of=/dev/sdX bs=1M conv=sync
```

The installation wizard is straightforward. Make sure your system is configured for UEFI
boot, and select `ZFS (GPT)` for the disk layout.

When prompted for base system installation type, choose `Packages` to get the new
[pkgbase](https://wiki.freebsd.org/action/show/pkgbase) goodness.

Once you reboot, login as root using the password you specified during installation.

## Hardware Devices, Drivers, and Tuning

First, we'll configure device drivers and make various tweaks to get optimum performance
and battery life out of a desktop system.

Many of these steps are not strictly necessary, but they work well for me. Use your own
judgment!

### Bootloader Tunables

First, open up `/boot/loader.conf` and consider the following:

```bash
# /boot/loader.conf

# Timeout at the bootloader prompt (seconds).
autoboot_delay="3"

# HaRdEniNg: 99% of users will never need destructive dtrace.
security.bsd.allow_destructive_dtrace="0"

# The defaults here are far to conservative for desktop stuff.
kern.ipc.shmseg="1024"
kern.ipc.shmmni="1024"
kern.maxproc="100000"

# If your system supports Intel Speed Shift (check dmesg), set this to 0.
# This will allow each core to adjust its power state independently.
machdep.hwpstate_pkg_ctrl="0"

# Enable PCI power saving.
hw.pci.do_power_nodriver="3"

# Enable faster soreceive() implementation. Beware if using BIND DNS server.
net.inet.tcp.soreceive_stream="1"

# Increase network interface queue length.
net.isr.defaultqlimit="2048"
net.link.ifqmaxlen="2048"

# For laptops, increase ZFS transaction timeout to save battery.
vfs.zfs.txg.timeout="10"
```

### Kernel Modules

Enable querying CPU information and temperature:

```bash
sysrc -v kld_list+="cpuctl coretemp"
```
The H-TCP congestion control algorithm is designed to perform better over fast,
long-distance networks (like the internet). You might consider using it:

```bash
sysrc -v kld_list+="cc_htcp"
```

If you're using a ThinkPad, you'll want this module to get various buttons working:

```bash
sysrc -v kld_list+="acpi_ibm"
```

### Sysctl Tweaks

Next, open up `/etc/sysctl.conf` and consider setting some of the following sysctls. Note that
you can view the description of any sysctl using `sysctl -d`.

```bash
# /etc/sysctl.conf

# ==================
# sEcuRitY HaRdeNinG
# ==================

# These are values are pretty common sense for the majority of people:
hw.kbd.keymap_restrict_change=4
kern.coredump=0
kern.elf32.aslr.pie_enable=1
kern.random.fortuna.minpoolsize=128
kern.randompid=1
net.inet.icmp.drop_redirect=1
net.inet.ip.process_options=0
net.inet.ip.random_id=1
net.inet.ip.redirect=0
net.inet.ip.rfc1122_strong_es=1
net.inet.tcp.always_keepalive=0
net.inet.tcp.drop_synfin=1
net.inet.tcp.icmp_may_rst=0
net.inet.tcp.syncookies=0
net.inet6.ip6.redirect=0
security.bsd.unprivileged_read_msgbuf=0

# Some guides will tell you use these. More trouble than they're worth, IMO:
#kern.elf32.allow_wx=0
#kern.elf64.allow_wx=0
#security.bsd.hardlink_check_gid=1
#security.bsd.hardlink_check_uid=1
#security.bsd.see_other_gids=0
#security.bsd.see_other_uids=0
#security.bsd.unprivileged_proc_debug=0


# ==========================
# Network Performance Tuning
# ==========================

# The default values for many of these sysctls are optimized for the TCP latencies
# of a LAN. The modifications below should result in better TCP
# performance over connections with a larger RTT (like the internet), at
# the expense of higher memory utilization.
#
# Source: it came to me in a dream
kern.ipc.maxsockbuf=2097152
kern.ipc.soacceptqueue=1024
kern.ipc.somaxconn=1024
net.inet.tcp.abc_l_var=44
net.inet.tcp.cc.abe=1
net.inet.tcp.cc.algorithm=htcp
net.inet.tcp.cc.htcp.adaptive_backoff=1
net.inet.tcp.cc.htcp.rtt_scaling=1
net.inet.tcp.ecn.enable=1
net.inet.tcp.fast_finwait2_recycle=1
net.inet.tcp.fastopen.server_enable=1
net.inet.tcp.finwait2_timeout=5000
net.inet.tcp.initcwnd_segments=44
net.inet.tcp.keepcnt=2
net.inet.tcp.keepidle=62000
net.inet.tcp.keepinit=5000
net.inet.tcp.minmss=536
net.inet.tcp.msl=2500
net.inet.tcp.mssdflt=1448
net.inet.tcp.nolocaltimewait=1
net.inet.tcp.recvbuf_max=2097152
net.inet.tcp.recvspace=65536
net.inet.tcp.sendbuf_inc=65536
net.inet.tcp.sendbuf_max=2097152
net.inet.tcp.sendspace=65536
net.local.stream.recvspace=65536
net.local.stream.sendspace=65536


# =====================
# Desktop Optimizations
# =====================

# Prevent shared memory from being swapped to disk.
kern.ipc.shm_use_phys=1

# Increase scheduler preemption threshold for snappier GUI experience.
kern.sched.preempt_thresh=224

# Allow unprivileged users to mount things.
vfs.usermount=1

# Don't switch virtual consoles back and forth on suspend.
# With some graphics cards, switching to a different VT breaks hardware acceleration.
# https://github.com/freebsd/drm-kmod/issues/175
kern.vt.suspendswitch=0


# ===================
# Laptop Power Saving
# ===================

# Decrease audio responsiveness to save power.
hw.snd.latency=7
```

### WiFi

Poor WiFi support is now a thing of the past, thanks to [LinuxKPI](https://wiki.freebsd.org/LinuxKPI)
and the new [iwlwifi](https://wiki.freebsd.org/WiFi/Iwlwifi) driver.
If you have one of the common Intel cards, chances are it will just work.

First, install the necessary firmware package for your wireless card:

```bash
fwget -v
```

To use the newer `iwlwifi` driver on older cards, you may need to block the old `iwm` driver from loading
in `loader.conf`:

```bash
# /boot/loader.conf

devmatch_blocklist="if_iwm"
```

802.11n and 802.11ac are disabled by default. You'll need another `loader.conf` tweak to unlock higher speeds:

```bash
# /boot/loader.conf

compat.linuxkpi.iwlwifi_11n_disable="0"
compat.linuxkpi.iwlwifi_disable_11ac="0"
```

Update `rc.conf` to create a `wlan0` device on boot:

```bash
sysrc -v wlans_iwlwifi0="wlan0" \
         create_args_wlan="wlanmode sta country US regdomain FCC" \
         ifconfig_wlan0="WPA DHCP powersave"
```

Those settings will cause `wpa_supplicant(8)` to manage your WiFi networks. You can either edit
`/etc/wpa_supplicant.conf` by hand, or use the graphical interface provided by `networkmgr`:

```bash
pkg install sudo networkmgr
```

Note that `networkmgr` requires superuser privileges. You can allow all memebers of the `operator`
group to run `networkmgr` without a password using `sudo`:

```bash
# /usr/local/etc/sudoers.d/networkmgr

%operator ALL=NOPASSWD: /usr/local/bin/networkmgr
```

#### Suspend and Resume Breaks WiFi

Unfortunately, there is an [iwlwifi bug](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=263632)
present in 15.1-RELEASE that results in broken WiFi after resuming from sleep.

Luckily, there is a simple workaround: simply disable the interface before suspend and
enable it after resume. Create a custom `rc.d` service:

```bash
#!/bin/sh
#
# /usr/local/etc/rc.d/iwlwifi_fix
#
# PROVIDE: iwlwifi_fix
# KEYWORD: suspend resume

. /etc/rc.subr

name="iwlwifi_fix"
extra_commands="suspend resume"
suspend_cmd="iwlwifi_fix_suspend"
resume_cmd="iwlwifi_fix_resume"

iwlwifi_fix_suspend(){
  /usr/sbin/service netif stop wlan0
}

iwlwifi_fix_resume(){
  /usr/sbin/service netif start wlan0
}

load_rc_config "$name"
run_rc_command "$1"
```

And enable it:

```bash
chmod +x /usr/local/etc/rc.d/iwlwifi_fix
sysrc -v iwlwifi_fix_enable="YES"
```

A fix has already been [committed](https://cgit.freebsd.org/src/commit/?id=0c0f66541aa220af38261af6360713ded6e3f15d)
to 15-STABLE, so hopefully this workaround will be unnecessary once FreeBSD 15.2 is released.

### CPU Microcode and Power Savings

Install the latest CPU microcode:

```bash
pkg install cpu-microcode
```

Edit `loader.conf` to load the microcode on boot:

```bash
# /boot/loader.conf

cpu_microcode_load="YES"
cpu_microcode_name="/boot/firmware/intel-ucode.bin"
```

You can save a **lot** of battery (and heat) by enabling lower CPU C-states:

```bash
sysrc -v performance_cx_lowest=Cmax economy_cx_lowest=Cmax
```

### Intel Graphics Driver

Install the Intel graphics driver and make sure it's loaded on boot:

```bash
pkg install drm-kmod libva-intel-media-driver
sysrc -v kld_list+="i915kms"
```

#### Audio Freezes on Laptops

There is an [i915 bug](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=229190)
on some laptops that results in hard lockups. The problem is accompanied by `dmesg` errors that
look like this:

```
hdac0: Command timeout 2
```

The solution is a simple loader tunable:

```bash
compat.linuxkpi.i915_disable_power_well=0
```

#### Graphics Freezes and GPU Hangs

With FreeBSD 15.1, the default DRM driver was bumped from version 6.6 to version 6.12.

Unfortunately, the new version appears to have a [bug](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=295625)
on some Intel chips that causes graphical freezes accompanied by `GPU HANG` messages in `dmesg`.

A reliable workaround is to simply continue using the previous version:

```bash
pkg install drm-66-kmod
```

### Linux Binary Compatibility

The [Linuxulator](https://wiki.freebsd.org/Linuxulator) allows you to run Linux binaries on FreeBSD:

```bash
sysrc -v linux_enable=YES
```

If you run Linux binaries, you will probably need to mount some Linux filesystems as well:

```bash
# /etc/fstab

devfs     /compat/linux/dev     devfs     rw,late 0 0
tmpfs     /compat/linux/dev/shm tmpfs     rw,late,size=1g,mode=1777 0 0
fdescfs   /compat/linux/dev/fd  fdescfs   rw,late,linrdlnk 0 0
linprocfs /compat/linux/proc    linprocfs rw,late 0 0
linsysfs  /compat/linux/sys     linsysfs  rw,late 0 0
```

### FUSE

If you ever want to mount filesystems like exFAT or NTFS, you'll need FUSE:

```bash
sysrc -v kld_list+=fusefs
```

### Webcams

With any luck, your webcam will be supported by `webcamd` without any fuss:

```bash
pkg install webcamd v4l-utils
sysrc -v webcamd_enable=YES
```

### Device Permissions via devfs

For desktop systems, you'll need a custom `devfs(8)` ruleset to allow unprivileged users to
control common hardware devices. Create `/etc/devfs.rules` with the following:

```dosini
# /etc/devfs.rules

[localrules=1000]
add path 'drm/*'       mode 0660 group operator
add path 'backlight/*' mode 0660 group operator
add path 'video*'      mode 0660 group operator
add path 'usb/*'       mode 0660 group operator
```

And set your default ruleset like so:

```bash
sysrc -v devfs_system_ruleset=localrules
```

### USB Power Saving

If you’re using a laptop, you’ll want to power down inactive USB devices to save battery life.

Add the following to `/etc/rc.local`:

```bash
# /etc/rc.local

usbconfig | awk -F: '{ print $1 }' | xargs -rtn1 -I% usbconfig -d % power_save
```

### ThinkPad Backlight Controls

I had to do a bit of work to get the backlight keys working on my ThinkPad X1 Carbon.

First, make sure the `acpi_ibm` kernel module is loaded:

```bash
kldload acpi_ibm
```

Then, set the following sysctl to allow `devd(8)` to handle events for the backlight buttons:

```bash
sysctl dev.acpi_ibm.0.handlerevents='0x10 0x11'
```

Make sure you add that to `/etc/sysctl.conf`!

Now we can receive the button events, but we'll need a `devd(8)` rule to handle them.
Create `/etc/devd/thinkpad-brightness.conf` with the following:

```
# /etc/devd/thinkpad-brightness.conf

notify 20 {
  match "system"    "ACPI";
  match "subsystem" "IBM";
  match "notify"    "0x10";
  action            "/usr/local/libexec/thinkpad-brightness up";
};

notify 20 {
  match "system"    "ACPI";
  match "subsystem" "IBM";
  match "notify"    "0x11";
  action            "/usr/local/libexec/thinkpad-brightness down";
};
```

Finally, create the following script at `/usr/local/libexec/thinkpad-brightness`:

```bash
#!/bin/sh
#
# /usr/local/libexec/thinkpad-brightness

cur=$(/usr/bin/backlight -q)

case $1 in
  up)
      if [ "$cur" -ge 50 ]; then
        delta=10
      elif [ "$cur" -ge 10 ]; then
        delta=5
      else
        delta=2
      fi
      /usr/bin/backlight incr "$delta"
    ;;
  down)
      if [ "$cur" -le 10 ]; then
        delta=2
      elif [ "$cur" -le 50 ]; then
        delta=5
      else
        delta=10
      fi
      /usr/bin/backlight decr "$delta"
    ;;
esac
```

Don’t forget to make it executable:

```bash
chmod 755 /usr/local/libexec/thinkpad-brightness
```

### Reboot

Now is a good time to reboot and make sure your changes haven't broken anything!

```bash
reboot
```

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
