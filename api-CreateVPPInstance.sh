#!/bin/bash

# Create a Device Enrollment Instance with the supplied Token

# Created: 5.23.2022 @robjschroeder
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

# Organization Name
OrgName=""

# Volume Purchasing sToken
sToken=""

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
	# Organization Name
	if [ $OrgName = "" ]; then
		read -p "Please enter the Organization name: " OrgName
	fi
	# sToken Value
	if [ $sToken = "" ]; then
		read -p "Please enter your sToken value: " sToken
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

# Create a Volume Purchasing Location
createVPP(){
	curl --request POST \
	--url ${jamfProURL}/api/v1/volume-purchasing-locations \
	--header 'Accept: application/json' \
	--header 'Content-Type: application/json' \
	--header "Authorization: Bearer ${token}" \
	--data '
{
	"automaticallyPopulatePurchasedContent": true,
	"sendNotificationWhenNoLongerAssigned": true,
	"autoRegisterManagedUsers": true,
	"siteId": "-1",
	"name": "'"${OrgName}"' VPP",
	"serviceToken": "'"${sToken}"'"
}
'
}

#
##################################################
# Script Work
#
#
# Calling all functions

checkVariables 
checkTokenExpiration
createVPP 
invalidateToken

exit 0