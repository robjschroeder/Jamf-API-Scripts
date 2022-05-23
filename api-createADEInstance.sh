#!/bin/bash

# Create a Device Enrollment Instance with the supplied Token

# Created: 5.23.2022 @robjschroeder

##################################################
# Variables -- edit as needed

# Organization Name
OrgName="AnyOrg Inc"

# Jamf Pro API Credentials
jamfProAPIUsername="api_Username"
jamfProAPIPassword="api_Password"
jamfProURL="https://server.jamfcloud.com"

# Automated Device Enrollment: The base 64 encoded token
# Provide path to .p7m file, remove any spaces from the filename
ADETokenPath="/Users/username/Downloads/ADEToken.p7m"

#
##################################################
# Functions -- do not edit below here

getBearerToken(){
	# Encode credentials
	encodedCredentials=$( printf "${jamfProAPIUsername}:${jamfProAPIPassword}" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )
	
	# Generate an auth token
	authToken=$( /usr/bin/curl "${jamfProURL}/uapi/auth/tokens" \
		--silent \
		--request POST \
		--header "Authorization: Basic ${encodedCredentials}" 
)
	
	# Parse authToken for token, omit expiration
	token=$( /usr/bin/awk -F \" '{ print $4 }' <<< "${authToken}" | /usr/bin/xargs )
}

invalidateToken(){
	curl --request POST \
	--url ${jamfProURL}/api/v1/auth/invalidate-token \
	--header 'Accept: application/json' \
	--header "Authorization: Bearer ${token}"
}

# Base64 encode token
encodeToken(){
	encodedADEToken=$(/usr/bin/base64 ${ADETokenPath})
}

# Create a Device Enrollment Instance with the supplied Token
createADE(){
	curl --request POST \
	--url ${jamfProURL}/api/v1/device-enrollments/upload-token \
	--header 'Accept: application/json' \
	--header 'Content-Type: application/json' \
	--header "Authorization: Bearer ${token}" \
	--data '
{
	"tokenFileName": "'"${OrgName}"' Automated Device Enrollment",
	"encodedToken": "'"${encodedADEToken}"'"
}
'
}

#
##################################################
# Script Work
#
#
# Create a Device Enrollment Instance with the supplied Token
if [ -z $ADETokenPath ]; then
	echo "ADE Token Path empty, please provide a path to the .p7m token"
else
	encodeToken 
	getBearerToken
	createADE
	invalidateToken
fi

exit 0
