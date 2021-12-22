#!/bin/bash

# Specifiy location of text file with computer ids that you want to delete from Jamf Pro
file="~/Desktop/ids.txt"

# Add API credentials
username="apiUser"
password="apiPassword"
URL="https://server.jamfcloud.com"

# Encode Creds
encodedCredentials=$( printf "$username:$password" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )

# generate an auth token
authToken=$( /usr/bin/curl "$URL/uapi/auth/tokens" \
--silent \
--request POST \
--header "Authorization: Basic $encodedCredentials" )

# parse authToken for token, omit expiration
token=$( /usr/bin/awk -F \" '{ print $4 }' <<< "$authToken" | /usr/bin/xargs )

ids+=($(cat $file))

for id in "${ids[@]}"; do
	echo "Delete computer: $id"
	curl -X DELETE "$URL/api/v1/computers-inventory/$id" -H "accept: */*" -H "Authorization: Bearer $token"
done
