#!/bin/sh
#
# Script will generate a bearer token for use
# with JPAPI using API Client and Secret
#
# Created 12.02.2023 @robjschroeder

##################################################
# Variables -- edit as needed

# Jamf Pro API Credentials
jamfProAPIClient=""
jamfProAPISecret=""
jamfProURL=""

# Token declarations
token=""

#
##################################################
# Functions -- do not edit below here

# Get a bearer token for Jamf Pro API Authentication
getBearerToken(){
	# Encode credentials
	curl_response=$(curl --silent --location --request POST "${jamfProURL}/api/oauth/token" --header "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=${jamfProAPIClient}" --data-urlencode "grant_type=client_credentials" --data-urlencode "client_secret=${jamfProAPISecret}")
	# Extract the token value
	if [[ $(echo "${curl_response}" | grep -c 'token') -gt 0 ]]; then
		echo "Authentication token successfully generated"
		token=$(echo "${curl_response}" | plutil -extract access_token raw -)
		echo "$curlResponse"
	else
		echo "Auth Error: Response from Jamf Pro API access token request did not contain a token. Verify the ClientID and ClientSecret values."
		exit 1
	fi
}

checkVariables(){
	# Checking for Jamf Pro API variables
	if [ -z $jamfProAPIClient ]; then
		echo "Please enter your Jamf Pro Client ID: "
		read -r jamfProAPIClient
	fi
	
	if [  -z $jamfProAPISecret ]; then
		echo "Please enter your Jamf Pro Client Secret for $jamfProAPIClient: "
		read -r -s jamfProAPIPassword
	fi
	
	if [ -z $jamfProURL ]; then
		echo "Please enter your Jamf Pro URL (with no slash at the end): "
		read -r jamfProURL
	fi
	
	# Checking for additional variables
}

# Invalidate the token when done
invalidateToken(){
	responseCode=$(/usr/bin/curl -w "%{http_code}" -H "Authorization: Bearer ${token}" ${jamfProURL}/api/v1/auth/invalidate-token -X POST -s -o /dev/null)
	if [[ ${responseCode} == 204 ]]
	then
		/bin/echo "Token successfully invalidated"
		token=""
	elif [[ ${responseCode} == 401 ]]
	then
		/bin/echo "Token already invalid"
	else
		/bin/echo "An unknown error occurred invalidating the token"
	fi
}

#
##################################################
# Script Work
#
#
# Calling all functions

checkVariables
getBearerToken
/usr/bin/curl -s -H "Authorization: Bearer ${token}" ${jamfProURL}/api/v1/jamf-pro-version -X GET
echo ""
invalidateToken

exit 0
