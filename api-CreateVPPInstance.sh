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

# Volume Purchasing sToken
sToken="eyJleHBEYXRlIjoiMjAyMy0wNS0xOVQxODo0MDo0OSswMDAwIiwidG9rZW4iOiJrVzhYWTlHcWg5azlmQ3A4NjZZZjdzbzZ1OHNpY01nclB5RXdyUVcrNTUzd0NkUVdkdWxzZVl0dFVUSjRYZngzaENxNFZaYW43TmZDRjlwSm1KQWNzbitjSXVES0JzU3VQaHJHNk9sYyt1WlpvSDVESTdOaHpJejlBSHVIYzRKRUhUenFCTkVkUktMUXZwOHczV05EblQvbHFRSWQzZlRkMVgwRE43Y2ZVOUl4NytxYTFDeHAvemtMaHpYQXJWNGg=="

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

# Create a Volume Purchasing Location
if [ -z ${sToken} ]; then
	echo "Value for sToken is blank, please provide this data"
else
	getBearerToken
	createVPP
	invalidateTo
fi

exit 0
