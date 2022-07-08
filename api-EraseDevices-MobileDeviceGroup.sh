#!/bin/bash

# This API script will:
# 1. Look at the membership of a specific Mobile Device Group in Jamf Pro
# 2. For each device in the Smart Group, push an 'Erase Device' MDM Command
#
# Created 5.13.2022 @robjschroeder
#
# Updated 07.08.2022 @robjschroeder
#
# Add the Mobile Device Group ID variable
# Add the MDM Action, if different than EraseDevice
# https://developer.jamf.com/jamf-pro/reference/mobiledevicecommands

##################################################
# Variables -- edit as needed

# Jamf Pro API Credentials
jamfProAPIUsername=""
jamfProAPIPassword=""
jamfProURL=""

# Token declarations
token=""
tokenExpirationEpoch="0"

# Smart Device Group ID in Jamf Pro
mobileDeviceGroupID=""

# MDM Action to be sent
action="EraseDevice"

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
	# Smart Device Group ID
	if [ $mobileDeviceGroupID = "" ]; then
		read -p "Please enter the ID number of the Smart Device Group you would like to take action on: " mobileDeviceGroupID
	fi
	# Action
	if [ $action = "" ]; then
		read -p "Please enter a value for the action variable: " action
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

sendMDMCommand(){
	# Get membership details of Mobile Device Group
	ids+=($(curl --request GET \
--url ${jamfProURL}/JSSResource/mobiledevicegroups/id/${mobileDeviceGroupID} \
--header 'Accept: application/xml' \
--header "Authorization: Bearer ${token}" | xmllint --format - | awk -F'>|<' '/<id>/{print $3}' | sort -n))
	
	for id in "${ids[@]}"; do
		if [[ $id -gt 0 ]]; then
			# Post Erase Device command to device
			curl --request POST \
			--url ${jamfProURL}/JSSResource/mobiledevicecommands/command/${action}/id/${id} \
			--header 'Content-Type: application/xml' \
			--header "Authorization: Bearer ${token}"
		else
			echo "Device id ${id} invalid, skipping..."
		fi
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
sendMDMCommand 
invalidateToken

exit 0