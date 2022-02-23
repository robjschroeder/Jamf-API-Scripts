#!/bin/zsh
#
# Script will generate a bearer token for use
# with JPAPI
#
# Updated: 2.22.2022 @ Robjschroeder                 
#
# Variables
#
# API credentials
apiUsername=""
apiPassword=""
jssURL=""
#
# Check for input on variables, prompt if empty
#
# Empty Username
if [ -z ${apiUsername} ]; then
	echo "Please enter your Jamf Pro username: "
	read $apiUsername
fi
# Empty Password
if [ -z ${apiPassword} ]; then
	echo "Please enter your Jamf Pro password: "
	read $apiPassword
fi
# Empty jssURL
if [ -z ${jssURL} ]; then
	echo "Please enter your Jamf Pro URL: "
	echo "(ex. https://server.jamfcloud.com)"
	read $jssURL
fi

# Create base64-encoded credentials
encodedCredentials=$( printf "${apiUsername}:${apiPassword}" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )

# Generate an auth token
authToken=$( /usr/bin/curl "${jssURL}/uapi/auth/tokens" \
--silent \
--request POST \
--header "Authorization: Basic ${encodedCredentials}" )

token=$( /usr/bin/awk -F \" '{ print $4 }' <<< "${authToken}" | /usr/bin/xargs )

echo ${token}
