#!/bin/bash

#Add API credentials
username="$4"
password="$5"
URL=$( defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url | sed s'/.$//' )

## Get Logged In User

loggedInUser=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ {print $3}')

## Get Serial Of Device

serial=$( system_profiler SPHardwareDataType | awk '/Serial/{print $NF}')

## Get Chrome email address

#chromestate=$(cat /Users/$loggedInUser/Library/Application\ Support/Google/Chrome/Local\ State | grep user_name)

#user_email=$(echo $chromestate | grep -o -E 'user_name":"[^"]+' | cut -d ':' -f 2 | tr -d '"' | grep shift\.com)

# Update Computer Record in Jamf Pro

curl -su "$username":"$password" -H "content-type: text/xml" $URL/JSSResource/computers/serialnumber/$serial -X PUT -d "<computer><location><email_address>test@test.com</email_address></location></computer>"
