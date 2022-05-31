#!/bin/bash

# Get the Jamf Pro Startup Status for
# Jamf Pro Server

# Variables -- edit these based on needs
#

# Jamf Pro Instances Array
instances=(
	https://server1.jamfcloud.com
	https://server2.jamfcloud.com
	https://server3.jamfcloud.com
	https://server4.jamfcloud.com
	https://server5.jamfcloud.com
)

#
##################################################
# Script Work -- do not edit below here
while :
do
# Loop through each instance in the 
# instance array
for inst in ${instances[@]}; do
	URL="${inst}"
	JPInstance=$( echo ${URL} | sed 's|^http[s]://||g' | sed 's/\..*//' | tr '[a-z]' '[A-Z]' )
	
	# Returns curl health check error from Jamf Pro if found
	echo -n "Status ${JPInstance} Server Health Check ===>"
	curl -k -m 5 -s ${inst}/healthCheck.html
	serverstat01=$(echo $?)
	# do not put anything between the curl command above and the variable that collects the output
	if [ ! $serverstat01 = '0' ]; then
		echo "Checking again: ${JPInstance}"
		echo -n "Status ${JPInstance} Server check 2 ===>"
		curl -k -m 5 -s ${inst}/healthCheck.html
		serverstat01=$(echo $?)
		if [ ! $serverstat01 = '0' ]; then
			echo -n "${JPInstance}: ERROR from curl is: $serverstat01"
		fi
	fi
	sleep 30
done
done
exit 0
