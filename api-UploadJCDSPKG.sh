#!/bin/bash

# Upload a PKG to JCDS
# JCDS will need to already be configured in Jamf Pro
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

pathToPKG=""

#
##################################################
# Functions -- do not edit below here

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
	# Path to .pkg
	if [ ${pathToPKG} = "" ]; then
		read - "Please drag your PKG file into terminal: " pathToPKG
	fi
}

uploadPKG(){
	# Upload PKG to JCDS
	uploadPKG(){
		# Get the PKG name
		pkg_name=$(basename "$pathToPKG")
		
		curl -X POST ${jamfProURL}/dbfileupload \
		-u ${jamfProAPIUsername}:${jamfProAPIPassword} \
		-H 'DESTINATION: 0' \
		-H 'OBJECT_ID: -1' \
		-H 'FILE_TYPE: 0' \
		-H "FILE_NAME: ${pkg_name}" \
		-T "${pathToPKG}"
	}
}

#
##################################################
# Script Work
#
#
# Calling all functions

checkVariables 
uploadPKG 

exit 0