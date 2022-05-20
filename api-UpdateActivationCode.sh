#!/bin/bash

# This Jamf Pro API script will update the
# activation code on Jamf Pro with the one
# provided in the variables.
#
# Created 5.20.2022 @robjschroeder

# Jamf Pro API Credentials
jamfProAPIUsername="api_Username"
jamfProAPIPassword="api_Password"
jamfProURL="https://server.jamfcloud.com"

# Activation Code Details
orgName=""
activationCode=""

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

updateActivationCode(){
	curl --request PUT \
	--url ${jamfProURL}/JSSResource/activationcode \
	--header 'Content-Type: application/xml' \
	--data '{"organization_name":"'"${orgName}"'","code":"'"${activationCode}"'"}'
}

getBearerToken

updateActivationCode 

invalidateToken 

exit 0
