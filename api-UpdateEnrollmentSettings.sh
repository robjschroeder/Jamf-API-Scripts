#!/bin/bash

# Update enrollment object. Regarding the developerCertificateIdentity,
# if this object is omitted, the certificate will not be deleted from Jamf Pro.
# The identityKeystore is the entire cert file as a base64 encoded string. The
# md5Sum field is not required in the PUT request, but is calculated and returned
# in the response.
#
# Created 07.08.2022 @robjschroeder

##################################################
# Variables -- edit as needed

# Jamf Pro API Credentials
jamfProAPIUsername=""
jamfProAPIPassword=""
jamfProURL=""

# Token declarations
token=""
tokenExpirationEpoch="0"

OrgName=""

# Default Enrollment (UIE) Settings
enrollmentData=$(cat <<EOF
{
	"installSingleProfile" : true,
	"signingMdmProfileEnabled" : false,
	"restrictReenrollment" : false,
	"flushLocationInformation" : true,
	"flushLocationHistoryInformation" : true,
	"flushPolicyHistory" : true,
	"flushExtensionAttributes" : true,
	"flushMdmCommandsOnReenroll" : "DELETE_EVERYTHING",
	"macOsEnterpriseEnrollmentEnabled" : true,
	"managementUsername" : "${OrgShortName}_jss",
	"managementPasswordSet" : false,
	"passwordType" : "RANDOM",
	"randomPasswordLength" : 17,
	"createManagementAccount" : false,
	"hideManagementAccount" : false,
	"allowSshOnlyManagementAccount" : false,
	"ensureSshRunning" : false,
	"launchSelfService" : false,
	"signQuickAdd" : false,
	"iosEnterpriseEnrollmentEnabled" : true,
	"iosPersonalEnrollmentEnabled" : false,
	"personalDeviceEnrollmentType" : "USERENROLLMENT",
	"accountDrivenUserEnrollmentEnabled" : false
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
	# Organizaiton Name
	if [ $OrgName = "" ]; then
		read -p "Please enter an Organization name: " OrgName
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

# Create Default UIE Settings
createEnrollment(){
	
	OrgShortName=$(echo $OrgName | sed 's/[^a-zA-Z0-9]//g')
	
	echo "$(date '+%A %W %Y %X'): Creating User-Initiated Enrollment settings..."
	curl --request PUT \
	--url ${jamfProURL}/api/v2/enrollment \
	--header 'Accept: application/json' \
	--header 'Content-Type: application/json' \
	--header "Authorization: Bearer ${token}" \
	--data "${enrollmentData}"
	sleep 1
	echo ""
}

#
##################################################
# Script Work
#
#
# Calling all functions

checkVariables 
checkTokenExpiration
createEnrollment 
invalidateToken

exit 0