#/bin/bash

# This Jamf Pro API script will initialize the Cloud
# Services Connection in Jamf Pro. A valid Jamf ID will
# need to be used for the csa variables.
#
# Created 4.26.2022 @robjschroeder
#
# Updated 5.23.2022 @robjschroeder
## Added functions to the script

##################################################
# Variables -- edit as needed

# Jamf Pro API Credentials
jamfProAPIUsername="api_Username"
jamfProAPIPassword="api_Password"
jamfProURL="https://server.jamfcloud.com"

# Jamf Nation Credentials
JNEmail="jamfNationUser@email.com"
JNPassword="jn_Password1234"

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

# Initialize the CSA token exchange
createCSA(){
	curl --request POST \
	--url ${jamfProURL}/api/v1/csa/token \
	--header 'Accept: application/json' \
	--header 'Content-Type: application/json' \
	--header "Authorization: Bearer ${token}" \
	--data '
{
	"emailAddress": "'"${JNEmail}"'",
	"password": "'"${JNPassword}"'"
}
'
}

#
##################################################
# Script Work
#
#
# Initialize Cloud Services Connection
if [ -z ${JNEmail} || -z ${JNPassword} ]; then
	echo "Jamf Nation credentials not defined, please verify"
else
	getBearerToken
	createCSA
	invalidateToken
fi

exit 0
