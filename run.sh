#!/usr/bin/env bash
# Change Paths
script=/home/niwo/Settings/Linux/scripts/BashDynamicPaper/dynamicWallpaper.sh
dir=/home/niwo/Nextcloud/MEDIA/Photo/Wallpapers/Dynamic
loc=EDLW

# DO NOT CHANGE BELOW
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$UID/bus"
$script -p $dir -w $loc
