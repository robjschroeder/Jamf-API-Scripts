#!/bin/bash

# Get the Jamf Pro Startup Status for
# Jamf Pro Server

# Variables -- edit these based on needs
#
jamfProURL="https://server.jamfcloud.com"


#
##################################################
# Script Work -- do not edit below here
while :
do
JPInstance=$( echo ${jamfProURL} | sed 's|^http[s]://||g' | sed 's/\..*//' | tr '[a-z]' '[A-Z]' )

# Returns curl health check error from Jamf Pro if found
echo -n "Status ${JPInstance} Server Health Check ===>"
curl -k -m 5 -s ${jamfProURL}/healthCheck.html
serverstat01=$(echo $?)
# do not put anything between the curl command above and the variable that collects the output
if [ ! $serverstat01 = '0' ]; then
	echo "Checking again: ${JPInstance}"
	echo -n "Status ${JPInstance} Server check 2 ===>"
	curl -k -m 5 -s ${jamfProURL}/healthCheck.html
	serverstat01=$(echo $?)
	if [ ! $serverstat01 = '0' ]; then
		echo -n "${JPInstance}: ERROR from curl is: $serverstat01"
	fi
fi
	
# Sleep 30 seconds between each check
sleep 30

done

exit 0
