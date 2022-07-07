#!/bin/bash 

# This script will grab all the ids of User objects in Jamf Pro, store them in an array
# loop through that array and send a delete command to the Users api endpoint. 
# Users that have devices assigned to them will not be deleted as the device acts
# as a dependency of their account. Only accounts that do not have a devices associated
# with it will be deleted
#
# Updated: 3.01.2022 @ Robjschroeder
# Updated: 07.07.2022 @robjschroeder

##################################################
# Variables -- edit as needed

# Jamf Pro API Credentials
jamfProAPIUsername=""
jamfProAPIPassword=""
jamfProURL=""

# Token declarations
token=""
tokenExpirationEpoch="0"

# Sleep options #
# Time to sleep between issuing commands to each device in seconds
commandSleep="1"
# Time to sleep between processing each batch in seconds
batchSleep="5"
## No need to change contents below ##


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
	# Command Sleep
	if [ $commandSleep = "" ]; then
		read -p "Please enter a value in seconds to sleep between each command: " commandSleep
	fi
	# Batch Sleep
	if [ $batchSleep = "" ]; then
		read -p "Please enter a value in seconds to sleep between batches: " batchSleep
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

deleteUnusedUsers(){
	# Always zero
	start=0
	# Number of item in the batch
	elements=10
	
	
	# Create array of IDs from our User base in Jamf Pro
	ids+=($(curl -H "Authorization: Bearer ${token}" -H "accept: text/xml" ${jamfProURL}/JSSResource/users -X GET | xmllint --format - | awk -F'>|<' '/<id>/{print $3}' | sort -n))
	
	for ((i = 0 ; i < ${#ids[@]} ; i++)); do
		id_list=($(echo ${ids[@]:$start:$elements}))
		if ! [  -z "${id_list}" ]; then
			for ((x = 0 ; x < ${#id_list[@]} ; x++)); do
				# Delete the user with ID number
				echo "Sending update command to delete User: ${id_list[$x]}" >> ~/Desktop/UserDelete.txt
				curl -H "Authorization: Bearer ${token}" -H "accept: text/xml" ${jamfProURL}/JSSResource/users/id/${id_list[$x]} -X DELETE >> ~/Desktop/UserDelete.txt
				# Time to wait between sending commands to each device
				sleep $commandSleep
			done
			echo "Processing next batch of ${elements}"
			# Time to wait between batches
			sleep $batchSleep
		else
			echo "Finished Processing"
			break
		fi
		(( start=start+${elements} ))
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
deleteUnusedUsers 
invalidateToken

exit 0