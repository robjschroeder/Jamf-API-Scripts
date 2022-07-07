#!/bin/bash

# This script will pass the username from the
# mobile devices mobile record into a separate
# EA field.
#
# Updated: 3.01.2022 @ Robjschroeder  
# Updated: 07.07.2022 @robjschroeder

##################################################
# Variables -- edit as needed

# Jamf Pro API Credentials
jamfProAPIUsername=""
jamfProAPIPassword=""
jamfProURL=""

# Token declarations
token=""
tokenExpirationEpoch="0"

# Enter the EA ID number that you would like
# to populate
EA="5"

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
	# EA
	if [ $EA = "" ]; then
		read -p "Please enter the extension attribute id that you would like update: " EA
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

updateMobileRecord(){
	# Grab the ids of all mobile devices and
	# store then in an array
	ids+=($(curl -s -H "accept: text/xml" -H "authorization: Bearer ${token}" -S ${jamfProURL}/JSSResource/mobiledevices -X GET | xmllint --format - | awk -F'>|<' '/<id>/{print $3}' | sort -n))
	
	for id in "${ids[@]}"; do
		deviceUser=$(curl -s -H "accept: text/xml" -H "authorization: Bearer ${token}" -S ${jamfProURL}/JSSResource/mobiledevices/id/${id} -X GET | xmllint --xpath "/mobile_device/location/username/text()" -)
		if [[ ! -z ${deviceUser} ]];then
			curl -s -H "content-type: text/xml" -H "authorization: Bearer ${token}" -S ${jamfProURL}/JSSResource/mobiledevices/id/${id} -X PUT -d "<mobile_device><extension_attributes><extension_attribute><id>${EA}</id><value>${deviceUser}</value></extension_attribute></extension_attributes></mobile_device>"
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
updateMobileRecord
invalidateToken

exit 0
