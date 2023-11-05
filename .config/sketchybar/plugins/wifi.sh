#!/bin/sh

# The wifi_change event supplies a $INFO variable in which the current SSID
# is passed to the script.

WIFI=${INFO:-"NC"}

if [ -z "$var" ]
then
  ICON=""
else
  ICON="󰤮"
fi

sketchybar --set $NAME icon="${ICON}" label="${WIFI}"
