#!/bin/sh
 
# This script will loop through an array of serial numbers of
# computers in Jamf Pro, then add those computers to a specific
# Static Computer Group. 

# Created 4.19.2022 @robjschroeder

# Updated 4.27.2022 @robjschroeder -- added token invalidation
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

# Array of serial numbers of macOS Computers in Jamf Pro
serialsArr=(
	FVFDNDA5MAAA
	C1MTG34THAAA
	V02IGL5D5AAA
)

# Jamf Pro Static Group Information
computerGroupID="53"
computerGroupName="Static Group Test"

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
	# Computer Group ID
	if [ $computerGroupID = "" ]; then
		read -p "Please enter the Jamf Pro id of the computer group you are modifying :" computerGroupID
	fi
	# Computer Group Name
	if [ $computerGroupName = "" ]; then
		read -p "Please enter the name of Jamf Pro Group ID $computerGroupID: " computerGroupName
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

addToStaticGroup(){
	# Loop through serials array, adding each serial to the static computer group
	for serial in ${serialsArr[@]}; do
		# Set API Data
		apiData="<computer_group><id>${computerGroupID}</id><name>${computerGroupName}</name><computer_additions><computer><serial_number>${serial}</serial_number></computer></computer_additions></computer_group>"
		# Put that computer in the static group
		curl --request PUT \
		--url ${jamfProURL}/JSSResource/computergroups/id/${computerGroupID} \
		--header "Authorization: Bearer ${token}" --header "Content-Type: text/xml" \
		--data "${apiData}"
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
addToStaticGroup 
invalidateToken

exit 0