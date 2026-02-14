# linuxMintSoundOnPowerConnectDisconnect

## Overview

A HOWTO for enabling sound on power connect/disconnect in Linux Mint

This is a quick how-to for adding audio events for power connect and disconnect.
It was developed early 2026 in the context of Linux Mint v22.2

Keywords: linux mint | udev script | power connect disconnect | battery mains

## Motiviation

Linux Mint allows the configuration of sound alerts for lots of different events.

See 'System Settings' -> 'Sound' -> 'Sounds' tab

Configuring sound is available for many events including "Starting Cinnamon", "Leaving Cinnamon", "Switching workspace", and so on.

However, there is no option to configure sound events when connecting or disconnecting to/from a power source (mains).

My work computer is a Macbook and I've grown to appreciate this event. If I don't hear the audio notification, I go checking why the power isn't working...


## First attempt

First, a note that I tried the [BAMS applet](https://cinnamon-spices.linuxmint.com/applets/view/255). An AI recommendation for "linux mint cinnamon alert when plugging in laptop power" recommended this applet. It required several packages to add alerts, but I could not figure out how to add power connect/disconnect alerts.


## Solution

The solution involved writing a [udev](https://opensource.com/article/18/11/udev) script.

I followed looked at many tutorials which suggested listening to SUBSYSTEM=="power_supply" events.

### Links

I found some of these useful

Good primer
https://www.dotlinux.net/blog/tutorial-on-how-to-write-basic-udev-rules-in-linux/



https://forum.qubes-os.org/t/how-to-trigger-a-command-on-linux-when-disconnected-from-power/34178

https://dataswamp.org/~solene/2025-05-31-linux-killswitch-on-power-disconnect.html

https://bbs.archlinux.org/viewtopic.php?id=299129

https://superuser.com/questions/1417292/udev-rule-to-start-a-command-on-ac-battery-plug-unplug-event




** https://wiki.archlinux.org/title/Power_management#Using_a_script_and_a_udev_rule

The essential udev rules necessary to capture power connect/disconnect events


### Important notes

On Linux Mint, the system sound clip files are located:
`AUDIO_FILE_DIR="/usr/share/mint-artwork/sounds"`

The Linux Mint system sound clips are in Ogg Vorbis file. Needs package 'vorbis-tools' for support.
`$ sudo apt install vorbis-tools`

With udev, have to issue command to update rules after they're changed:
The `udevadm trigger` re-triggers events for new testing.
`$ udevadm control --reload-rules && udevadm trigger`

### Major issue -- udev/root user cannot access audio

The initial script I wrote wouldn't work since the user calling the event (`root`) isn't the current owner of the Pulse device and wasn'tn allows to play audio. I got around this by sudo'ing to the current UI user and then providing a pointer to the Pulse runtime state in `/run/user`.


### udev script

This supplied script `99-power-notices.rules` is installed into directory `/etc/udev/rules.d`

Contents:

```
# Call the 'udev-power-script.sh' when power status changes
SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN="/root/bin/udev-power-script.sh 0"
SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="/root/bin/udev-power-script.sh 1"
```

It just calls the bash script when the power status changes. This is pretty straight forward.

### bash script

See script 'udev-power-script.sh'.
I installed this in directory `/root/bin` for lack of a better place.

