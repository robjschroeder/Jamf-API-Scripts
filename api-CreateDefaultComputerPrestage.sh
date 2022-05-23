#!/bin/bash

# Create a Computer Prestage

# Created: 5.23.2022 @robjschroeder

##################################################
# Variables -- edit as needed

# Organization Name
OrgName="IMADEV"

# Jamf Pro API Credentials
jamfProAPIUsername="api_PowerAutomate"
jamfProAPIPassword="V6#w9zJzh2jVVG@&"
jamfProURL="https://imadev.jamfcloud.com"

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

invalidateToken(){
	curl --request POST \
	--url ${jamfProURL}/api/v1/auth/invalidate-token \
	--header 'Accept: application/json' \
	--header "Authorization: Bearer ${token}"
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
# Create Default Computer Prestage
if [ -z ${computerPrestageData} ]; then
	echo "Computer Prestage Data variable empty, please check the data"
else
	getBearerToken
	createComputerPrestage
	invalidateToken
fi

exit 0
