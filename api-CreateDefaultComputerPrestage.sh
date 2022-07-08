#!/bin/bash

# Create a Computer Prestage

# Created: 5.23.2022 @robjschroeder
# Updated 07.08.2022 @robjschroeder

##################################################
# Variables -- edit as needed

# Jamf Pro API Credentials
jamfProAPIUsername=""
jamfProAPIPassword=""
jamfProURL=""

# Token declarations
token=""
tokenExpirationEpoch="0"

# Organization Name
OrgName=""

# Default Prestage Variables, make sure all values are correct including the deviceEnrollmentProgramInstanceID for your Jamf Pro
computerPrestageData=$(cat <<EOF
{
	"keepExistingSiteMembership" : false,
	"enrollmentSiteId" : "-1",
	"id" : "1",
	"displayName" : "${OrgName} Default Prestage",
	"supportPhoneNumber" : "",
	"supportEmailAddress" : "",
	"department" : "",
	"mandatory" : true,
	"mdmRemovable" : false,
	"defaultPrestage" : true,
	"keepExistingLocationInformation" : false,
	"requireAuthentication" : false,
	"authenticationPrompt" : "",
	"deviceEnrollmentProgramInstanceId" : "1",
	"siteId" : "-1",
	"skipSetupItems" : {
		"Biometric" : true,
		"FileVault" : false,
		"iCloudDiagnostics" : true,
		"Diagnostics" : true,
		"Accessibility" : true,
		"AppleID" : true,
		"ScreenTime" : true,
		"Siri" : true,
		"DisplayTone" : true,
		"Restore" : true,
		"Appearance" : true,
		"Privacy" : true,
		"Payment" : true,
		"Registration" : true,
		"TOS" : true,
		"iCloudStorage" : true,
		"Location" : true
	},
	"locationInformation" : {
		"username" : "",
		"realname" : "",
		"phone" : "",
		"email" : "",
		"room" : "",
		"position" : "",
		"departmentId" : "-1",
		"buildingId" : "-1",
		"id" : "1",
		"versionLock" : 0
	},
	"purchasingInformation" : {
		"id" : "1",
		"leased" : false,
		"purchased" : true,
		"appleCareId" : "",
		"poNumber" : "",
		"vendor" : "",
		"purchasePrice" : "",
		"lifeExpectancy" : 0,
		"purchasingAccount" : "",
		"purchasingContact" : "",
		"leaseDate" : "1970-01-01",
		"poDate" : "1970-01-01",
		"warrantyDate" : "1970-01-01",
		"versionLock" : 0
	},
	"preventActivationLock" : true,
	"enableDeviceBasedActivationLock" : false,
	"anchorCertificates" : [ ],
	"enrollmentCustomizationId" : "0",
	"language" : "en",
	"region" : "US",
	"autoAdvanceSetup" : false,
	"customPackageIds" : [ ],
	"customPackageDistributionPointId" : "-1",
	"installProfilesDuringSetup" : false,
	"prestageInstalledProfileIds" : [ ],
	"enableRecoveryLock" : false,
	"recoveryLockPasswordType" : "MANUAL",
	"rotateRecoveryLockPassword" : false
}
EOF
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

checkVariables(){
	# Checking for Jamf Pro API variables
	if [ -z $jamfProAPIUsername ]; then
		echo "Please enter your Jamf Pro Username: "
		read -r jamfProAPIUsername
	fi
	
	if [  -z $jamfProAPIPassword ]; then
		echo "Please enter your Jamf Pro password for $jamfProAPIUsername: "
		read -r -s jamfProAPIPassword
	fi
	
	if [ -z $jamfProURL ]; then
		echo "Please enter your Jamf Pro URL (with no slash at the end): "
		read -r jamfProURL
	fi
	
	# Checking for additional variables
	# Organization Name
	if [ $OrgName = "" ]; then
		read -p "Please enter an Organization name: " orgName
	fi
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

# Create Default macOS PreStage
createComputerPrestage(){
	curl --request POST \
	--url ${jamfProURL}/api/v2/computer-prestages \
	--header 'Accept: application/json' \
	--header 'Content-Type: application/json' \
	--header "Authorization: Bearer ${token}" \
	--data "${computerPrestageData}"
}

#
##################################################
# Script Work
#
#
# Calling all functions

checkVariables 
checkTokenExpiration
createComputerPrestage 
invalidateToken

exit 0