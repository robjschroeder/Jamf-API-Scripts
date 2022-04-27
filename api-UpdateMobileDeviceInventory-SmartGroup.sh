#!/bin/bash

# This API script will:
# 1. Look at the membership of a specific Smart Device Group in Jamf Pro
# 2. For each device in the Smart Group, push an 'Update Inventory' MDM Command
#
# Created 4.27.2022 @robjschroeder
#
# Add the Smart Device Group ID variable
# Add the MDM Action, if different than UpdateInventory
# https://developer.jamf.com/jamf-pro/reference/mobiledevicecommands

# API Credentials
username="api_Username"
password="api_Password"
URL="https://server.jamfcloud.com"

# Smart Device Group ID in Jamf Pro
smartGroupID="1"

# MDM Action to be sent
action="UpdateInventory"

encodedCredentials=$( printf "$username:$password" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )

# generate an auth token
authToken=$( /usr/bin/curl "$URL/uapi/auth/tokens" \
--silent \
--request POST \
--header "Authorization: Basic $encodedCredentials" )

# parse authToken for token, omit expiration
token=$( /usr/bin/awk -F \" '{ print $4 }' <<< "$authToken" | /usr/bin/xargs )

# Get membership details of Smart Device Group
ids+=($(curl --request GET \
--url ${URL}/JSSResource/mobiledevicegroups/id/${smartGroupID} \
--header 'Accept: application/xml' \
--header "Authorization: Bearer ${token}" | xmllint --format - | awk -F'>|<' '/<id>/{print $3}' | sort -n))

for id in "${ids[@]}"; do
	if [[ $id -gt 0 ]]; then
		# Post Update Inventory command to device
		curl --request POST \
		--url ${URL}/JSSResource/mobiledevicecommands/command/${action}/id/${id} \
		--header 'Content-Type: application/xml' \
		--header "Authorization: Bearer ${token}"
	else
		echo "Device id ${id} invalid, skipping..."
	fi
done

# Invalidate the token
curl --request POST \
--url ${URL}/api/v1/auth/invalidate-token \
--header 'Accept: application/json' \
--header "Authorization: Bearer ${token}"

exit 0
