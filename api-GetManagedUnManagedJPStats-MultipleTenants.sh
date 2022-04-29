#!/bin/bash

# Get inventory status of multiple Jamf Pro 
# instances. 
#
# Created: 4.29.2022 @ Robjschroeder
#
##################################################
# Variables -- edit these based on needs
#
# Add API credentials
username="api_Username"
password="api_Password"
#
# Jamf Pro Instances Array
instances=(
	https://server1.jamfcloud.com
	https://server2.jamfcloud.com
	https://server3.jamfcloud.com
	https://server6.jamfcloud.com
	https://server9.onlinepcm.com
	https://server5.jamfcloud.com
	https://server4.jamfcloud.com
	https://servera.jamfcloud.com
	https://server1b.jamfcloud.com
	https://server22.jamfcloud.com
	https://server7.jamfcloud.com
	https://server12.jamfcloud.com
)
#
##################################################
# Functions -- do not edit below here

getBearerToken(){
	# Encode credentials
	encodedCredentials=$( printf "${username}:${password}" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )
	
	# Generate an auth token
	authToken=$( /usr/bin/curl "${URL}/uapi/auth/tokens" \
		--silent \
		--request POST \
		--header "Authorization: Basic ${encodedCredentials}" 
)
	
	# Parse authToken for token, omit expiration
	token=$( /usr/bin/awk -F \" '{ print $4 }' <<< "${authToken}" | /usr/bin/xargs )
}

invalidateToken(){
	curl --request POST \
	--url ${URL}/api/v1/auth/invalidate-token \
	--header 'Accept: application/json' \
	--header "Authorization: Bearer ${token}"
}

sortInstances(){
	# Sort array alphabetically
	instancesArr=$(echo ${instances[@]} | tr ' ' '\n' | sort)
}

##################################################
# Script work
#
# Sort the instances
sortInstances 

# Loop through each instance in the 
# instance array
for inst in ${instancesArr[@]}; do
	URL="${inst}"
	JPInstance=$( echo ${URL} | sed 's|^http[s]://||g' | sed 's/\..*//' | tr '[a-z]' '[A-Z]' )
	
	getBearerToken

	# Returns inventory information from Jamf Pro in JSON
	data=$( curl --request GET \
				--silent \
				--url ${URL}/api/v1/inventory-information \
				--header "Accept: application/json" \
				--header "Authorization: Bearer ${token}" \
				--output -
)
	# Store specific counts into variables
	managedComputers=$( echo ${data} | jq '.managedComputers')
	unmanagedComputers=$( echo ${data} | jq '.unmanagedComputers')
	managedDevices=$( echo ${data} | jq '.managedDevices')
	unmanagedDevices=$( echo ${data} | jq '.unmanagedDevices')
	totalCount=$((${unmanagedDevices} + ${managedDevices} + ${unmanagedComputers} + ${managedComputers}))
	
	echo ${JPInstance}
	echo "Managed Computers: ${managedComputers}"
	echo "Unmanaged Computers: ${unmanagedComputers}"
	echo "Managed Devices: ${managedDevices}"
	echo "Unmanaged Devices: ${unmanagedDevices}"
	echo "Total count: $totalCount"
	echo "--------------------------"
	
	invalidateToken 

done

exit 0