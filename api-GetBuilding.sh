#!/bin/sh

# Displays information of Building
# in Jamf Pro
#
# Updated: 3.03.2022 @ Robjschroeder  

# Variables

# Add API credentials
username="apiUsername"
password="apiPassword"
URL="https://server.jamf.com"

# Instance id of Building
id=""

# Generate encoded credentials
encodedCredentials=$( printf "${username}:${password}" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )

# Generate an auth token
authToken=$( /usr/bin/curl "${URL}/uapi/auth/tokens" \
--silent \
--request POST \
--header "Authorization: Basic ${encodedCredentials}" )

# Parse authToken for token, omit expiration
token=$( /usr/bin/awk -F \" '{ print $4 }' <<< "$authToken" | /usr/bin/xargs )

curl --request GET \
--url ${URL}/api/v1/buildings/${id} \
--header "Accept: application/json" \
--header "Authorization: Bearer ${token}" \
--output -

exit 0
