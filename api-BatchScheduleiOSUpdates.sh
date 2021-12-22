#!/bin/bash

### This script will use the API to schedule OS updates to mobile device belonging to a specific Smart Device Group. This may be helpful when attempting to schedule OS updates for more than 250 devices as this can be done in smaller batches. 

#Add API credentials
username="apiUser"
password="apiPassword"
URL="https://server.jamfcloud.com"

# Smart Device Group ID number
smartDeviceGroupID=""

# Update option
# 1 = Download the update for users to install
# 2 = Download and install the update, and restart devices after installation
updateOption=""

# Sleep options #
# Time to sleep between issuing commands to each device in seconds
commandSleep=""
# Time to sleep between processing each batch in seconds
batchSleep=""

## No need to change contents below ##

# Always zero
start=0
# Number of item in the batch
elements=2


# Create array of Serial Numbers for devices in Smart Device Group
serials+=($(curl -su $username:$password -H "accept: text/xml" $URL/JSSResource/mobiledevicegroups/id/$smartDeviceGroupID -X GET | xmllint --format - | awk -F'>|<' '/<serial_number>/{print $3}' | sort -n))

for ((i = 0 ; i < ${#serials[@]} ; i++)); do
	serial_list=($(echo ${serials[@]:$start:$elements}))
	if ! [  -z "${serial_list}" ]; then
		for ((x = 0 ; x < ${#serial_list[@]} ; x++)); do
			# Get IDs for each device in Smart Device Group
			id=$(curl -su $username:$password -H "accept: text/xml" $URL/JSSResource/mobiledevices/serialnumber/${serial_list[$x]} -X GET | xmllint --xpath "/mobile_device/general/id/text()" - )
			echo "Sending update command for Device: ${serial_list[$x]} with ID: $id"
			curl -su $username:$password -H "content-type: application/xml" $URL/JSSResource/mobiledevicecommands/command/ScheduleOSUpdate/$updateOption/id/$id -X POST
			# Time to wait between sending commands to each device
			sleep $commandSleep
		done
		echo "Processing next batch of ${elements}"
		# Time to wait between batches
		sleep $batchSleep
	else
		echo "Finished Processing"
		break
	fi
		(( start=start+${elements} ))
done
exit
