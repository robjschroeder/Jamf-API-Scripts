#!/bin/sh
 
# This script will loop through an array of serial numbers of
# computers in Jamf Pro, then add those computers to a specific
# Static Computer Group. 

# Created 4.19.2022 @robjschroeder

# Updated 4.27.2022 @robjschroeder -- added token invalidation

# Jamf User Credentials
jamfUser="apiUsername"
jamfPassword="apiPassword"
jssURL="https://server.jamfcloud.com"

# Jamf Pro Static Group Information
computerGroupID="53"
computerGroupName="Static Group Test"

# Array of serial numbers of macOS Computers in Jamf Pro
serialsArr=(
	FVFDNDA5MAAA
	C1MTG34THAAA
	V02IGL5D5AAA
)



# Encode credentials
encodedCredentials=$( printf "${jamfUser}:${jamfPassword}" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )
 
# Generate an auth token
authToken=$( /usr/bin/curl "${jssURL}/uapi/auth/tokens" \
--silent \
--request POST \
--header "Authorization: Basic ${encodedCredentials}"
)

# Parse authToken for bearer token, omit expiration
token=$( /usr/bin/awk -F \" '{ print $4 }' <<< "${authToken}" | /usr/bin/xargs )

# Loop through serials array, adding each serial to the static computer group
for serial in ${serialsArr[@]}; do
	# Set API Data
	apiData="<computer_group><id>${computerGroupID}</id><name>${computerGroupName}</name><computer_additions><computer><serial_number>${serial}</serial_number></computer></computer_additions></computer_group>"
	# Put that computer in the static group
	curl --request PUT \
	--url ${jssURL}/JSSResource/computergroups/id/${computerGroupID} \
	--header "Authorization: Bearer ${token}" --header "Content-Type: text/xml" \
	--data "${apiData}"
done

# Invalidate the token
curl --request POST \
--url ${URL}/api/v1/auth/invalidate-token \
--header 'Accept: application/json' \
--header "Authorization: Bearer ${token}"

exit 0
