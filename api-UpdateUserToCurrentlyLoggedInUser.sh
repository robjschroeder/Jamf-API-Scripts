#!/bin/bash

# This script will find the currently
# logged in user and then set that user 
# as the username in Jamf Pro
#
# Updated: 3.19.2022 @ Robjschroeder
#
# Update: 07.07.2022 @robjschroeder

##################################################
# Variables -- edit as needed

#--------------------------------------------------------------#

#Add API credentials
jamfProAPIUsername="$4"
jamfProAPIPassword="$5"
jamfProURL=$( defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url | sed s'/.$//' )

#--------------------------------------------------------------#

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

# Check the expiration of the bearer token
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

# Exit the script with a status of 1 if JPAPI information missing
exit1(){
	echo "Insufficient Jamf Pro API information"
	exit 1
}

#
##################################################
# Script Work
#

# Check Jamf Pro API variables
if [ $jamfProAPIUsername = "" ]; then
	echo "Jamf Pro API username not defined, exiting script"
	exit1
fi

if [ $jamfProAPIPassword = "" ]; then
	echo "Jamf Pro API password not defined, exiting script"
	exit1
fi

if [ $jamfProURL = "" ]; then
	echo "Jamf Pro URL not defined, exiting script"
	exit1
fi

## Get Logged In User
loggedInUser=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ {print $3}')

## Get Serial Of Device
serial=$( system_profiler SPHardwareDataType | awk '/Serial/{print $NF}')

# Update Computer Record in Jamf Pro
curl -H "Authorization: Bearer ${token}" -H "content-type: text/xml" ${jamfProURL}/JSSResource/computers/serialnumber/${serial} -X PUT -d "<computer><location><username>${loggedInUser}</username></location></computer>"

exit 0