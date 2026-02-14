# linuxMintSoundOnPowerConnectDisconnect

## Overview

A HOWTO for enabling sound on power connect/disconnect in Linux Mint

This is a quick how-to for adding audio events for power connect and disconnect.
It was developed early 2026 in the context of Linux Mint v22.2

Keywords: linux mint | udev script | power connect disconnect | battery mains

Stored in GitHub here: https://github.com/toddgee/linuxMintSoundOnPowerConnectDisconnect#

## Motiviation

Linux Mint allows the configuration of sound alerts for lots of different events.

See 'System Settings' -> 'Sound' -> 'Sounds' tab

Configuring sound is available for many events including "Starting Cinnamon", "Leaving Cinnamon", "Switching workspace", and so on.

However, there is no option to configure sound events when connecting or disconnecting to/from a power source (mains).

My work computer is a Macbook and I've grown to appreciate this event. If I don't hear the audio notification, I go checking why the power isn't working...

I wanted the same feature for my new laptop.

## First attempt - use BAMS applet

First, a note that I tried the [BAMS applet](https://cinnamon-spices.linuxmint.com/applets/view/255). An AI recommendation for "linux mint cinnamon alert when plugging in laptop power" recommended this applet. It required several packages to add alerts, but I could not figure out how to add power connect/disconnect alerts.

## Solution

The solution involved writing a [udev](https://opensource.com/article/18/11/udev) script.

I followed looked at many tutorials which suggested listening to SUBSYSTEM=="power_supply" events.

### Links

I found some of these useful

Good primer on writing 'udev' scripts:<br>
https://www.dotlinux.net/blog/tutorial-on-how-to-write-basic-udev-rules-in-linux/

Contains the essential rules for monitoring 'udev' power connection/disconnect rules.<br>
Other pages I found suggested using `ENV{POWER_SUPPLY_ONLINE}=="1"`, but the events published by 'udev' on my Linux Mint system included 'ATTR{online}=="1"'...<br>
https://wiki.archlinux.org/title/Power_management#Using_a_script_and_a_udev_rule

### Important notes

On Linux Mint, the system sound clip files are located:<br>
`AUDIO_FILE_DIR="/usr/share/mint-artwork/sounds"`

The Linux Mint system sound clips are in Ogg Vorbis file. Needs package 'vorbis-tools' for support.<br>
`$ sudo apt install vorbis-tools`

With udev, have to issue command to update rules after they're changed:<br>
(The `udevadm trigger` re-triggers events for new testing.)<br>
`$ udevadm control --reload-rules && udevadm trigger`

### Issues encountered

#### Event `ATTR{online}=="1"` fires twice

I initially used a basic script to play audio on event.

However, I noticed that the `ATTR{online}=="1"` event, fired when power was connected, would fire twice. (The disconnect event, `ATTR{online}=="0"` would only fire once.)

To get around this, I used a temp file to track the last value of the event and only play the audio if the state actually changed.

#### udev/root user cannot access audio

The initial script I wrote wouldn't work since the user calling the event (`root`) isn't the current owner of the Pulse device and wasn'tn allows to play audio.

I got around this by sudo'ing to the current UI user and then providing a pointer to the Pulse runtime state in `/run/user`.

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

See script 'udev-power-script.sh'.<br>
I installed this in directory `/root/bin` for lack of a better place.

#### Calling event only once

Because the `ATTR{online}=="1"` fires twice, I added this to the script:

```
# Current value in state file
currentState=""
if [ -r "${STATE_FILE}" ]; then
	currentState="$( cat $STATE_FILE )"
	if [ "${currentState}" != "0" -a "${currentState}" != "1" ]; then
		# echo "invalid current state"
		currentState=""
	fi
fi

# Make a sound if new state
if [ "${newState}" != "${currentState}" ]; then

	if [ "${newState}" = "0" ]; then
		playAudio "${ON_BATTERY_AUDIOFILE}"

	elif [ "${newState}" = "1" ]; then
		playAudio "${ON_AC_AUDIOFILE}"

	fi

	# Save new state
	echo "${newState}" > "${STATE_FILE}"

fi
```

This ensures we'll only get a single audio event regardless of how many times the event is published.


#### Playing audio thru Pulse as root

The important bits of this script are here:

```
# Gets the logged in user (Pulse owner)
getPulseUser() {
	ps -ef | grep pipewire-pulse | grep -v grep | cut -d' ' -f1
}

# Returns the UID of the given user
# $1 - the username
getUserID() {
	local username="${1}"
	id -u "${username}"
}

# Plays the given audio file as the currently logged in user
playAudio() {
	local audioFile="${1}"

	local pulseUser="$( getPulseUser )"
	local pulseUID="$( getUserID "${pulseUser}" )"

	# Setting the 'XDG_RUNTIME_DIR' environment variable allws access to pulse
	su - ${pulseUser} -c "XDG_RUNTIME_DIR=/run/user/${pulseUID} /usr/bin/ogg123 -q '${audioFile}'"
}
```

The `playAudio()` function will look up the userId and username of the currently logged in user and, by passing the environment variable `XDG_RUNTIME_DIR=/run/user/${pulseUID}`, will connect to the current Pluse user.

I don't know what happens if there's nobody currently logged in.<br>
Generally, that's not a worry as I'm usually logged into my laptop.

