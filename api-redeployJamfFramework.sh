#!/bin/sh

# Redeploys the Jamf Management Framework 
# for enrolled device
#
# Updated: 3.09.2022 @ Robjschroeder  

# Variables

# Add API credentials
username="apiUsername"
password="apiPassword"
URL="https://jamf.pro.com"

# Instance id of computer
id=""


encodedCredentials=$( printf "${username}:${password}" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )

# Generate an auth token
authToken=$( /usr/bin/curl "${URL}/uapi/auth/tokens" \
--silent \
--request POST \
--header "Authorization: Basic ${encodedCredentials}" )

# Parse authToken for token, omit expiration
token=$( /usr/bin/awk -F \" '{ print $4 }' <<< "$authToken" | /usr/bin/xargs )

curl --request POST \
--url ${URL}/api/v1/jamf-management-framework/redeploy/${id} \
--header "Accept: application/json" \
--header "Authorization: Bearer ${token}"

exit 0
