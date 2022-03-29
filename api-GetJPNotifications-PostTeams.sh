#!/bin/bash

# Get information about important 
# notifications in Jamf Pro then post
# the results to a Microsoft Teams channel
# via a webhook
#
# Updated: 3.28.2022 @ Robjschroeder  
#
# Variables
#
# Add API credentials
username="apiUsername"
password="apiPassword"
URL="https://server.jamfcloud.com"
JPInstance=$( echo ${URL} | sed 's|^http[s]://||g' | sed 's/\..*//' | tr '[a-z]' '[A-Z]' )

# Webhook for Teams created with https://docs.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook
TeamsWebhookURL=""

encodedCredentials=$( printf "${username}:${password}" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )

# Generate an auth token
authToken=$( /usr/bin/curl "${URL}/uapi/auth/tokens" \
--silent \
--request POST \
--header "Authorization: Basic ${encodedCredentials}" 
)

# Parse authToken for token, omit expiration
token=$( /usr/bin/awk -F \" '{ print $4 }' <<< "${authToken}" | /usr/bin/xargs )

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

# Returns important notifications from Jamf Pro in JSON
data=$( curl --request GET \
--url "${URL}/api/v1/notifications" \
--header "Accept: application/json" \
--header "Authorization: Bearer ${token}" \
)

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
		# Generate data to post to Teams chat
		generate_post_data()
		{
			cat <<EOF
{
	"text":"$message"
}
EOF
		}
		
		# Send message to Teams Webhook
		curl -H "Content-Type: application/json" -d "$(generate_post_data)" $TeamsWebhookURL
		
	fi
done
	
exit 0
