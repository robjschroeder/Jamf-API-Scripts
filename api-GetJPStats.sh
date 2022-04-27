#!/bin/sh

# Get basic information about the Jamf Pro Server
# Preview version of the endpoint. There may still 
# be some breaking changes in the future.
#
# Updated: 3.03.2022 @ Robjschroeder  
#
# Updated: 4.27.2022 @robjschroeder -- added token invalidation

# Variables

# Add API credentials
username="apiUsername"
password="apiPassword"
URL="https://server.jamf.com"

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
--url ${URL}/api/v1/jamf-pro-information \
--header "Accept: application/json" \
--header "Authorization: Bearer ${token}" \
--output -

# Invalidate the token
curl --request POST \
--url ${URL}/api/v1/auth/invalidate-token \
--header 'Accept: application/json' \
--header "Authorization: Bearer ${token}"

exit 0
