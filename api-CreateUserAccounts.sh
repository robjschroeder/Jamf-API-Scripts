#!/bin/bash

# Jamf Pro API script to build categories
# Created: 5.23.2022 @robjschroeder

################################
# Variables - edit as needed

# Jamf Pro API Credentials
jamfProAPIUsername="apiUsername"
jamfProAPIPassword="apiPassword"
jamfProURL="https://server.jamfcloud.com"

# Create additional Jamf Pro administrators, these accounts will be created with a temporary password and forced to change upon first login
jamfProUsers="username1, First Last, First.Last@org.com
username2, First Last, First.Last@org.com
username3, First Last, First.Last@org.com
username4, First Last, First.Last@org.com"

# Temporary Password
tempPassword="T3mpP@ssw0rd"

#
##################################################
# Functions -- no need to edit below

# Get a bearer token for Jamf Pro API Authentication
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

# Invalidate the token when done
invalidateToken(){
	curl --request POST \
	--url ${jamfProURL}/api/v1/auth/invalidate-token \
	--header 'Accept: application/json' \
	--header "Authorization: Bearer ${token}"
}

# Create additional Jamf Pro Administrators
createJamfAdmins(){
	echo "$(date '+%A %W %Y %X'): Creating Jamf Pro Administrator accounts..."
	# Create local CSV of the defined Jamf Pro Users
	echo "$jamfProUsers" > /tmp/jamfProUsers.csv
	
	INPUT="/tmp/jamfProUsers.csv"
	OLDIFS=$IFS
	IFS=','
	[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }
	while read username displayname email
	do
		curl --request POST \
		--url ${jamfProURL}/JSSResource/accounts/userid/0 \
		--header 'Accept: application/xml' \
		--header 'Content-Type: application/xml' \
		--header "Authorization: Bearer ${token}" \
		--data "<account><name>${username}</name><full_name>${displayname}</full_name><email>${email}</email><email_address>${email}</email_address><enabled>Enabled</enabled><privilege_set>Administrator</privilege_set><password>${tempPassword}</password><force_password_change>true</force_password_change></account>"
	done < $INPUT
	IFS=$OLDIFS
	sleep 1
	echo ""
}

#
##################################################
# Script Work
#

getBearerToken
createJamfAdmins
invalidateToken

exit 0
