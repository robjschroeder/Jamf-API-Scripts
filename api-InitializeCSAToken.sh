#/bin/bash

# This Jamf Pro API script will initialize the Cloud
# Services Connection in Jamf Pro. A valid Jamf ID will
# need to be used for the csa variables.
#
# Created 4.26.2022 @robjschroeder
#

# Variables
#
# Add API credentials
username="api_Username"
password="api_Password"
URL="https://server.jamfcloud.com/"

# CSA Token Credentials
csa_username="csa_Username"
csa_password="csa_Password"

encodedCredentials=$( printf "${username}:${password}" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )

# Generate an auth token
authToken=$( /usr/bin/curl "${URL}/uapi/auth/tokens" \
--silent \
--request POST \
--header "Authorization: Basic ${encodedCredentials}" 
)

# Parse authToken for token, omit expiration
token=$( /usr/bin/awk -F \" '{ print $4 }' <<< "${authToken}" | /usr/bin/xargs )


curl --request POST \
--url ${URL}/api/v1/csa/token \
--header 'Accept: application/json' \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer ${token}" \
--data '
{
	"emailAddress": "${csa_username}",
	"password": "${csa_password}"
}
'

# Invalidate the token
curl --request POST \
--url ${URL}/api/v1/auth/invalidate-token \
--header 'Accept: application/json' \
--header "Authorization: Bearer ${token}"

exit 0
