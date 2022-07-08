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
# Updated 07.08.2022 @robjschroeder

##################################################
# Variables -- edit as needed

# Jamf Pro API Credentials
jamfProAPIUsername=""
jamfProAPIPassword=""
jamfProURL=""

# Token declarations
token=""
tokenExpirationEpoch="0"

# Smart Device Group ID number
smartDeviceGroupID=""

# Update option
# 1 = Download the update for users to install
# 2 = Download and install the update, and restart
# devices after installation
updateOption=""

# Sleep options
# Time to sleep between issuing commands to each
# device in seconds
commandSleep=""

# Time to sleep between processing each batch in
# seconds
batchSleep=""

#
##################################################
# Functions -- do not edit below here

# Get a bearer token for Jamf Pro API Authentication
getBearerToken(){
	# Encode credentials
	encodedCredentials=$( printf "${jamfProAPIUsername}:${jamfProAPIPassword}" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )
	authToken=$(/usr/bin/curl -s -H "Authorization: Basic ${encodedCredentials}" "${jamfProURL}"/api/v1/auth/token -X POST)
	token=$(/bin/echo "${authToken}" | /usr/bin/plutil -extract token raw -)
	tokenExpiration=$(/bin/echo "${authToken}" | /usr/bin/plutil -extract expires raw - | /usr/bin/awk -F . '{print $1}')
	tokenExpirationEpoch=$(/bin/date -j -f "%Y-%m-%dT%T" "${tokenExpiration}" +"%s")
}

checkVariables(){
	# Checking for Jamf Pro API variables
	if [ -z $jamfProAPIUsername ]; then
		echo "Please enter your Jamf Pro Username: "
		read -r jamfProAPIUsername
	fi
	
	if [  -z $jamfProAPIPassword ]; then
		echo "Please enter your Jamf Pro password for $jamfProAPIUsername: "
		read -r -s jamfProAPIPassword
	fi
	
	if [ -z $jamfProURL ]; then
		echo "Please enter your Jamf Pro URL (with no slash at the end): "
		read -r jamfProURL
	fi
	
	# Checking for additional variables
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
}

checkTokenExpiration() {
	nowEpochUTC=$(/bin/date -j -f "%Y-%m-%dT%T" "$(/bin/date -u +"%Y-%m-%dT%T")" +"%s")
	if [[ tokenExpirationEpoch -gt nowEpochUTC ]]
	then
		/bin/echo "Token valid until the following epoch time: " "${tokenExpirationEpoch}"
	else
		/bin/echo "No valid token available, getting new token"
		getBearerToken
	fi
}

# Invalidate the token when done
invalidateToken(){
	responseCode=$(/usr/bin/curl -w "%{http_code}" -H "Authorization: Bearer ${token}" ${jamfProURL}/api/v1/auth/invalidate-token -X POST -s -o /dev/null)
	if [[ ${responseCode} == 204 ]]
	then
		/bin/echo "Token successfully invalidated"
		token=""
		tokenExpirationEpoch="0"
	elif [[ ${responseCode} == 401 ]]
	then
		/bin/echo "Token already invalid"
	else
		/bin/echo "An unknown error occurred invalidating the token"
	fi
}

sendiOSUpdate(){
	# Always zero
	start=0
	# Number of item in the batch
	elements=2
	
	# Create array of Serial Numbers for devices in Smart Device Group
	serials+=($(curl -H "Authorization: Bearer ${token}" -H "accept: text/xml" ${jamfProURL}/JSSResource/mobiledevicegroups/id/${smartDeviceGroupID} -X GET | xmllint --format - | awk -F'>|<' '/<serial_number>/{print $3}' | sort -n))
	# Loop through each serial in array
	for ((i = 0 ; i < ${#serials[@]} ; i++)); do
		serial_list=($(echo ${serials[@]:$start:$elements}))
		if ! [  -z "${serial_list}" ]; then
			for ((x = 0 ; x < ${#serial_list[@]} ; x++)); do
				# Get IDs for each device in Smart Device Group
				id=$(curl -H "Authorization: Bearer ${token}" -H "accept: text/xml" ${jamfProURL}/JSSResource/mobiledevices/serialnumber/${serial_list[$x]} -X GET | xmllint --xpath "/mobile_device/general/id/text()" - )
				# Update command listed below
				echo "Sending update command for Device: ${serial_list[$x]} with ID: $id"
				curl -H "Authorization: Bearer ${token}" -H "content-type: application/xml" ${jamfProURL}/JSSResource/mobiledevicecommands/command/ScheduleOSUpdate/${updateOption}/id/${id} -X POST
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
}

#
##################################################
# Script Work
#
#
# Calling all functions

checkVariables 
checkTokenExpiration
sendiOSUpdate 
invalidateToken

exit 0