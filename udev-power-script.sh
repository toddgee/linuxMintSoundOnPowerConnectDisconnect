#!/bin/bash

# A sscript called by udev
# See /etc/udev/rules.d/99-power-notices.rules
# Called with single parameter:
#    0 - On Battery
#    1 - On AC
#
# Script might get multiple calls so only performs audio when state changes.
# Because of this, we capture the incoming state to a temp file and only play
# the sound if the state has changed.
#
# Envisioned to live: ~root/bin/udev-power-script.sh
#

# current state flie
STATE_FILE="/tmp/udev-power-state"

# Audio files to play when going onto Battery and going onto AC
AUDIO_FILE_DIR="/usr/share/mint-artwork/sounds"
ON_BATTERY_AUDIOFILE="${AUDIO_FILE_DIR}/unplug.oga"
ON_AC_AUDIOFILE="${AUDIO_FILE_DIR}/plug.oga"


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


# Parameter handling
# expects one parameter: "0" (power disconnected) or "1" (power connected)
newState="${1}"
if [ "${newState}" != "0" -a "${newState}" != "1" ]; then
	# echo "invalid parameter"
	exit 1
fi

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

