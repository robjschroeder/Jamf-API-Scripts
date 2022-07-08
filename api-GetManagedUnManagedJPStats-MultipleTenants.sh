#!/bin/bash

# Get inventory status of multiple Jamf Pro 
# instances. 
#
# Created: 4.29.2022 @ Robjschroeder
#
# Updated 07.08.2022 @robjschroeder

##################################################
# Variables -- edit as needed

# Jamf Pro API Credentials
jamfProAPIUsername=""
jamfProAPIPassword=""

# Token declarations
token=""
tokenExpirationEpoch="0"

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
	
	# Checking for additional variables
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

sortInstances(){
	# Sort array alphabetically
	instancesArr=$(echo ${instances[@]} | tr ' ' '\n' | sort)
}

getInventory(){
	# Loop through each instance in the 
	# instance array
	for inst in ${instancesArr[@]}; do
		jamfProURL="${inst}"
		JPInstance=$( echo ${jamfProURL} | sed 's|^http[s]://||g' | sed 's/\..*//' | tr '[a-z]' '[A-Z]' )
		
		checkTokenExpiration 
		
		# Returns inventory information from Jamf Pro in JSON
		data=$( curl --request GET \
				--silent \
				--url ${jamfProURL}/api/v1/inventory-information \
				--header "Accept: application/json" \
				--header "Authorization: Bearer ${token}" \
				--output -
)
		# Store specific counts into variables
		managedComputers=$( echo ${data} | jq '.managedComputers')
		unmanagedComputers=$( echo ${data} | jq '.unmanagedComputers')
		managedDevices=$( echo ${data} | jq '.managedDevices')
		unmanagedDevices=$( echo ${data} | jq '.unmanagedDevices')
		totalCount=$((${unmanagedDevices} + ${managedDevices} + ${unmanagedComputers} + ${managedComputers}))
		
		echo ${JPInstance}
		echo "Managed Computers: ${managedComputers}"
		echo "Unmanaged Computers: ${unmanagedComputers}"
		echo "Managed Devices: ${managedDevices}"
		echo "Unmanaged Devices: ${unmanagedDevices}"
		echo "Total count: $totalCount"
		echo "--------------------------"
		
		invalidateToken 
		
	done
}

#
##################################################
# Script Work
#
#
# Calling all functions

checkVariables 
sortInstances 
getInventory 
invalidateToken

exit 0