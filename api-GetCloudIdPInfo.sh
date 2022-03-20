#!/bin/bash

# Get information about all Cloud Identity
# Providers configurations

# Add API credentials
username="apiUsername"
password="apiPassword"
URL="https://server.pro.com"


encodedCredentials=$( printf "${username}:${password}" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )

# Generate an auth token
authToken=$( /usr/bin/curl "${URL}/uapi/auth/tokens" \
--silent \
--request POST \
--header "Authorization: Basic ${encodedCredentials}" )

# Parse authToken for token, omit expiration
token=$( /usr/bin/awk -F \" '{ print $4 }' <<< "$authToken" | /usr/bin/xargs )

# Returns basic informations about all configured Cloud Identity Provider
curl --request GET \
--url "$URL/api/v1/cloud-idp?page=0&page-size=100&sort=id%3Adesc" \
--header "Accept: application/json" \
--header "Authorization: Bearer $token"

exit 0