#!/bin/bash

# This script will find the currently
# logged in user and then set that user 
# as the username in Jamf Pro
#
# Updated: 3.19.2022 @ Robjschroeder  

# Variables

#Add API credentials
username="$4"
password="$5"
URL=$( defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url | sed s'/.$//' )

## Get Logged In User

loggedInUser=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ {print $3}')

## Get Serial Of Device

serial=$( system_profiler SPHardwareDataType | awk '/Serial/{print $NF}')

# Update Computer Record in Jamf Pro

curl -su "${username}":"${password}" -H "content-type: text/xml" ${URL}/JSSResource/computers/serialnumber/${serial} -X PUT -d "<computer><location><username>${loggedInUser}</username></location></computer>"

exit 0