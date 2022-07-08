#!/bin/bash

# Get information about important 
# notifications in Jamf Pro
#
# Updated: 3.28.2022 @ Robjschroeder  
#
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

# Build an array of possible important notifications from Jamf Pro
noticationsArr=(
	APNS_CERT_REVOKED
	APNS_CONNECTION_FAILURE
	APPLE_SCHOOL_MANAGER_T_C_NOT_SIGNED
	BUILT_IN_CA_EXPIRED
	BUILT_IN_CA_EXPIRING
	BUILT_IN_CA_RENEWAL_FAILED
	BUILT_IN_CA_RENEWAL_SUCCESS
	CLOUD_LDAP_CERT_EXPIRED
	CLOUD_LDAP_CERT_WILL_EXPIRE
	COMPUTER_SECURITY_SSL_DISABLED
	DEP_INSTANCE_EXPIRED
	DEP_INSTANCE_WILL_EXPIRE
	DEVICE_ENROLLMENT_PROGRAM_T_C_NOT_SIGNED
	EXCEEDED_LICENSE_COUNT
	FREQUENT_INVENTORY_COLLECTION_POLICY
	GSX_CERT_EXPIRED
	GSX_CERT_WILL_EXPIRE
	HCL_BIND_ERROR
	HCL_ERROR
	INSECURE_LDAP
	INVALID_REFERENCES_EXT_ATTR
	INVALID_REFERENCES_POLICIES
	INVALID_REFERENCES_SCRIPTS
	JAMF_CONNECT_UPDATE
	JAMF_PROTECT_UPDATE
	JIM_ERROR
	LDAP_CONNECTION_CHECK_THROUGH_JIM_FAILED
	LDAP_CONNECTION_CHECK_THROUGH_JIM_SUCCESSFUL
	MDM_EXTERNAL_SIGNING_CERTIFICATE_EXPIRED
	MDM_EXTERNAL_SIGNING_CERTIFICATE_EXPIRING
	MDM_EXTERNAL_SIGNING_CERTIFICATE_EXPIRING_TODAY
	MII_HEARTBEAT_FAILED_NOTIFICATION
	MII_INVENTORY_UPLOAD_FAILED_NOTIFICATION
	MII_UNATHORIZED_RESPONSE_NOTIFICATION
	PATCH_EXTENTION_ATTRIBUTE
	PATCH_UPDATE
	POLICY_MANAGEMENT_ACCOUNT_PAYLOAD_SECURITY_MULTIPLE
	POLICY_MANAGEMENT_ACCOUNT_PAYLOAD_SECURITY_SINGLE
	PUSH_CERT_EXPIRED
	PUSH_CERT_WILL_EXPIRE
	PUSH_PROXY_CERT_EXPIRED
	SSO_CERT_EXPIRED
	SSO_CERT_WILL_EXPIRE
	TOMCAT_SSL_CERT_EXPIRED
	TOMCAT_SSL_CERT_WILL_EXPIRE
	USER_INITIATED_ENROLLMENT_MANAGEMENT_ACCOUNT_SECURITY_ISSUE
	USER_MAID_DUPLICATE_ERROR
	USER_MAID_MISMATCH_ERROR
	USER_MAID_ROSTER_DUPLICATE_ERROR
	VPP_ACCOUNT_EXPIRED
	VPP_ACCOUNT_WILL_EXPIRE
	VPP_TOKEN_REVOKED
	DEVICE_COMPLIANCE_CONNECTION_ERROR
	CONDITIONAL_ACCESS_CONNECTION_ERROR
	AZURE_AD_MIGRATION_REPORT_GENERATED
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

checkNotifications(){
	# Returns important notifications from Jamf Pro in JSON
	data=$( curl --request GET \
--url "${jamfProURL}/api/v1/notifications" \
--header "Accept: application/json" \
--header "Authorization: Bearer ${token}" \
)
	JPInstance=$( echo ${jamfProURL} | sed 's|^http[s]://||g' | sed 's/\..*//' | tr '[a-z]' '[A-Z]' )
	
	# Loop each notification possibility and if it
	# exists in the results, grab information on the
	# notification using jq and notify
	for str in ${noticationsArr[@]}; do
		if [[ " ${data} " =~ ${str} ]]; then
			# Create a clean string because the webhook doesn't like "_"
			cleanString=$( echo ${str} | sed 's/_/ /g' )
			name=$( echo ${data} | jq --arg v "${str}" '.[]|select(.type==$v).params.name')
			# Create a clean name because the webhook doesn't like """
			cleanname=$( echo ${name} | sed 's/"//g')
			days=$( echo ${data} | jq --arg v "${str}" '.[]|select(.type==$v).params.days')
			id=$( echo ${data} | jq --arg v "${str}" '.[]|select(.type==$v).params.id')
			if [[ ${name} != "null" ]]; then
				if [[ ${days} != "null" ]]; then
					if [[ ${id} != "null" ]]; then
						message=$( echo "${JPInstance} Notification: ${cleanString} for ${cleanname} in ${days} days" )
							else
							message=$( echo "${JPInstance} Notification: ${cleanString} for ${cleanname} in ${days} days" )
								fi
								else
								message=$( echo "${JPInstance} Notification: ${cleanString} for ${name}" )
									fi
									else
									message=$( echo "${JPInstance} Notification: ${cleanString}" )
									fi
									# Results expected to look like:
									# JAMFPRO Notification: DEP INSTANCE WILL EXPIRE for DEP Instance in 18 days
									# or
									# JAMFPRO Notification: EXCEEDED LICENSE COUNT
									
									echo ${message}
									fi
								done
}

#
##################################################
# Script Work
#
#
# Calling all functions

checkVariables 
checkTokenExpiration
checkNotifications 
invalidateToken

exit 0