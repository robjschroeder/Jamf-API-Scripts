#!/bin/zsh
#
# Script will use the API to schedule OS updates to  
# mobile device belonging to a specific Smart Device  
# Group. This may be helpful when attempting to      
# schedule OS updates for more than 250 devices as   
# this can be done in smaller batches.               
#
# Updated: 2.21.2022 @ Robjschroeder                 
#
# Variables
#
# API credentials
apiUsername=""
apiPassword=""
jssURL=""
#
# Smart Device Group ID number
smartDeviceGroupID=""
#
# Update option
# 1 = Download the update for users to install
# 2 = Download and install the update, and restart
# devices after installation
updateOption=""
#
# Sleep options
# Time to sleep between issuing commands to each
# device in seconds
commandSleep=""
# Time to sleep between processing each batch in
# seconds
batchSleep=""
#
#
########## No need to change contents below ##########
# Always zero
start=0
# Number of item in the batch
elements=2
#
# Check for input on variables, prompt if empty
#
# Empty Username
if [ -z ${apiUsername} ]; then
	echo "Please enter your Jamf Pro username: "
	read $apiUsername
fi
# Empty Password
if [ -z ${apiPassword} ]; then
	echo "Please enter your Jamf Pro password: "
	read $apiPassword
fi
# Empty jssURL
if [ -z ${jssURL} ]; then
	echo "Please enter your Jamf Pro URL: "
	echo "(ex. https://server.jamfcloud.com)"
	read $jssURL
fi
# Empty smartDeviceGroupID
if [ -z ${smartDeviceGroupID} ]; then
	echo "Please enter the ID of your Smart Device Group: "
	read $smartDeviceGroupID
fi
# Empty updateOption
if [ -z ${updateOption} ]; then
	echo "1 = Download the update for users to install"
	echo "2 = Download and install the update, and restart devices after installation"
	echo "Please enter your update option: "
	read $updateOption
fi
# Empty commandSleep
if [ -z ${commandSleep} ]; then
	echo "Time to sleep between issuing commands to each device in seconds"
	read $commandSleep
fi
# Empty batchSleep
if [ -z ${batchSleep} ]; then
	echo "Time to sleep between processing each batch in seconds "
	read $batchSleep
fi

# Create array of Serial Numbers for devices in Smart Device Group
serials+=($(curl -su ${apiUsername}:${apiPassword} -H "accept: text/xml" ${jssURL}/JSSResource/mobiledevicegroups/id/${smartDeviceGroupID} -X GET | xmllint --format - | awk -F'>|<' '/<serial_number>/{print $3}' | sort -n))
# Loop through each serial in array
for ((i = 0 ; i < ${#serials[@]} ; i++)); do
	serial_list=($(echo ${serials[@]:$start:$elements}))
	if ! [  -z "${serial_list}" ]; then
		for ((x = 0 ; x < ${#serial_list[@]} ; x++)); do
			# Get IDs for each device in Smart Device Group
			id=$(curl -su ${apiUsername}:${apiPassword} -H "accept: text/xml" ${jssURL}/JSSResource/mobiledevices/serialnumber/${serial_list[$x]} -X GET | xmllint --xpath "/mobile_device/general/id/text()" - )
			# Update command listed below
			echo "Sending update command for Device: ${serial_list[$x]} with ID: $id"
			curl -su ${apiUsername}:${apiPassword} -H "content-type: application/xml" ${jssURL}/JSSResource/mobiledevicecommands/command/ScheduleOSUpdate/${updateOption}/id/${id} -X POST
			# Time to wait between sending commands to each device
			sleep ${commandSleep}
		done
		echo "Processing next batch of ${elements}"
		# Time to wait between batches
		sleep ${batchSleep}
	else
		echo "Finished Processing"
		break
	fi
	(( start=start+${elements} ))
done

exit
