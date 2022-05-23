#!/bin/bash

# Create mulitple categories in Jamf Pro

# Created: 5.23.2022 @robjschroeder

##################################################
# Variables -- edit as needed

# Jamf Pro API Credentials
jamfProAPIUsername="api_Username"
jamfProAPIPassword="api_Password"
jamfProURL="https://server.jamfcloud.com"

# Create categories, modify array of categories to be created in Jamf Pro, make sure spaces are escaped
categories=(
	Applications
	Enrollment
	Inventory
	Security
	Software\ Updates
	Test\ Category\ 1
	Test\ Category\ 2
	Testing
)

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

# Create category records
createCategories(){
	for category in "${categories[@]}"; do
	curl --request POST \
	--url ${jamfProURL}/api/v1/categories \
	--header 'Accept: application/json' \
	--header 'Content-Type: application/json' \
	--header "Authorization: Bearer ${token}" \
	--data '{"name": "'"${category}"'","priority": 9}'
done
}

#
##################################################
# Script Work
#
#
# Create Category records
if [ -z ${categories} ]; then
	echo "Categories array is empty, please add some categories"
else
	getBearerToken
	createCategories
	invalidateToken
fi

exit 0
