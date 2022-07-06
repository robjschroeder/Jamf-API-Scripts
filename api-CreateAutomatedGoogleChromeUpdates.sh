#!/bin/bash

# This script will help in the automatic updating of software titles using 
# Jamf Pro's built in Patch Management module, Smart Computer Groups, and policies. 
#
# The policy used to update uses the Installomator.sh script, this should already be uploaded into your
# Jamf Pro before running this script. 
#
# This script will:
# 1. Create a Patch Management Software Title for Google Chrome
# 2. Create a Smart Computer Group that looks for computers with a less than "x" verison
# 3. Create an ongoing and recurring check-in policy that uses the Installomator.sh script to install Google Chrome, scoped to the Smart Computer Group created in Step 2. 
# 4. Updates the Smart Group created in step 2 to use 'Latest Version' as the criteria. 
# 5. There is no step 5....
#
# Created 07.06.2022 @robjschroeder

##################################################
# Variables -- edit as needed

# Jamf Pro API Credentials
jamfProAPIUsername="apiUsername"
jamfProAPIPassword="apiPassword"
jamfProURL="https://server.jamfcloud.com"

# Token declarations
token=""
tokenExpirationEpoch="0"

# Array of Patch MGMT Software Titles to add to Jamf Pro from GitHub
computerPatchURL=(
	# Google Chrome
	https://raw.githubusercontent.com/robjschroeder/JamfPatchSoftwareTitles/main/SoftwareTitle-GoogleChrome.xml
)

# Array of policy URLs to upload to Jamf Pro
computerPoliciesURL=(
	# Applications - Google Chrome - Auto Update
	https://raw.githubusercontent.com/robjschroeder/Jamf-Policies/main/Applications-GoogleChrome-AutoUpdate.xml
)

# Array of computer smart group URLs to upload to Jamf Pro
computerGroupURL=(
	# App Needs Update - Google Chrome
	https://raw.githubusercontent.com/robjschroeder/Jamf-Smart-Groups/main/AppNeedsUpdate-GoogleChrome.xml
)
#
##################################################
# Functions -- do not edit below here

# Get a bearer token for Jamf Pro API Authentication
getBearerToken(){
	# Encode credentials
	encodedCredentials=$( printf "${jamfProAPIUsername}:${jamfProAPIPassword}" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )
	authToken=$(/usr/bin/curl -s -H "Authorization: Basic ${encodedCredentials}" "${jamfProURL}"/api/v1/auth/token -X POST)
	token=$(/bin/echo "${authToken}" | /usr/bin/plutil -extract token raw -)
	tokenExpiration=$(/bin/echo "${authToken}" | /usr/bin/plutil -extract expires raw - | /usr/bin/awk -F . '{print $1}')
	tokenExpirationEpoch=$(/bin/date -j -f "%Y-%m-%dT%T" "${tokenExpiration}" +"%s")
}

checkTokenExpiration() {
	nowEpochUTC=$(/bin/date -j -f "%Y-%m-%dT%T" "$(/bin/date -u +"%Y-%m-%dT%T")" +"%s")
	if [[ tokenExpirationEpoch -gt nowEpochUTC ]]
	then
		/bin/echo "Token valid until the following epoch time: " "${tokenExpirationEpoch}"
	else
		/bin/echo "No valid token available, getting new token"
		getBearerToken
	fi
}

# Invalidate the token when done
invalidateToken(){
	responseCode=$(/usr/bin/curl -w "%{http_code}" -H "Authorization: Bearer ${token}" ${jamfProURL}/api/v1/auth/invalidate-token -X POST -s -o /dev/null)
	if [[ ${responseCode} == 204 ]]
	then
		/bin/echo "Token successfully invalidated"
		token=""
		tokenExpirationEpoch="0"
	elif [[ ${responseCode} == 401 ]]
	then
		/bin/echo "Token already invalid"
	else
		/bin/echo "An unknown error occurred invalidating the token"
	fi
}

# Upload computer configuration profiles from Github to Jamf Pro
uploadComputerPatchSoftwareTitles(){
	echo "$(date '+%A %W %Y %X'): Uploading Computer Configuration Profiles from GitHub..."
	for computerPatch in ${computerPatchURL[@]}; do
		computerPatchData=$(curl --silent $computerPatch)
		curl --request POST \
		--url ${jamfProURL}/JSSResource/patchsoftwaretitles/id/0 \
		--header 'Accept: application/xml' \
		--header 'Content-Type: application/xml' \
		--header "Authorization: Bearer ${token}" \
		--data "${computerPatchData}"
		sleep 1
	done
	sleep 1
	echo ""
}

# Upload computer policies from Github to Jamf Pro
uploadComputerPolicies(){
	echo "$(date '+%A %W %Y %X'): Uploading Computer Policies from GitHub..."
	for computerPolicy in "${computerPoliciesURL[@]}"; do
		computerPolicyData=$(curl --silent $computerPolicy)
		curl --request POST \
		--url ${jamfProURL}/JSSResource/policies/id/0 \
		--header 'Accept: application/xml' \
		--header 'Content-Type: application/xml' \
		--header "Authorization: Bearer ${token}" \
		--data "${computerPolicyData}"
		sleep 1
	done
	sleep 1
	echo ""
}

# Upload Computer Smart Groups
uploadComputerGroups(){
	echo "$(date '+%A %W %Y %X'): Uploading Computer Groups from GitHub..."
	for computerGroup in "${computerGroupURL[@]}"; do
		computerGroupData=$(curl --silent $computerGroup)
		curl --request POST \
		--url ${jamfProURL}/JSSResource/computergroups/id/0 \
		--header 'Accept: application/xml' \
		--header 'Content-Type: application/xml' \
		--header "Authorization: Bearer ${token}" \
		--data "${computerGroupData}"
		sleep 1
	done
	sleep 1
	echo ""
}

updateSG(){
	curl --request PUT \
	--url ${jamfProURL}/JSSResource/computergroups/name/App%20Needs%20Update%20-%20Google%20Chrome \
	--header 'Accept: application/xml' \
	--header 'Content-Type: application/xml' \
	--header "Authorization: Bearer ${token}" \
	--data "<computer_group><criteria><criterion><name>Patch Reporting: Google Chrome</name><priority>0</priority><and_or>and</and_or><search_type>less than</search_type><value>Latest Version</value></criterion></criteria></computer_group>"
}
#
##################################################
# Script Work
#
#
# Calling all functions

checkTokenExpiration
uploadComputerPatchSoftwareTitles 
uploadComputerGroups 
# Sleep for 30 seconds, because the policy may not be able to match the scope to the Smart Group that was just created
sleep 30
uploadComputerPolicies 
updateSG
invalidateToken

exit 0
