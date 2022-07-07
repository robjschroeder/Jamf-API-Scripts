#!/bin/bash

# Get the enrollment date of all computers in Jamf Pro
#
# Created 07.07.2022 @robjschroeder

##################################################
# Variables -- edit as needed

# Jamf Pro API Credentials
jamfProAPIUsername=""
jamfProAPIPassword=""
jamfProURL=""

# Token declarations
token=""
tokenExpirationEpoch="0"

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

getEnrollmentDate(){
	# Get a list of all computer IDs in Jamf Pro for the loop
	ids+=($(curl -s -H "accept: text/xml" -H "authorization: Bearer ${token}" -S ${jamfProURL}/JSSResource/computers -X GET | xmllint --format - | awk -F'>|<' '/<id>/{print $3}' | sort -n))
	# Loop through each ID, use the stylesheet to present the date
	for id in "${ids[@]}"; do
		curl --request GET --silent \
		--url ${jamfProURL}/JSSResource/computers/id/$id \
		--header "Authorization: Bearer ${token}" | xsltproc /tmp/stylesheet.xslt -
	done
}

cleanUp(){
	rm -rf /tmp/stylesheet.xslt
}

#
##################################################
# Script Work
#
#
# Calling all functions

#######################################
# Create an XSLT file at /tmp/stylesheet.xslt
#######################################
cat << EOF > /tmp/stylesheet.xslt
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:template match="/"> 
<xsl:text>Computer Name: </xsl:text>
<xsl:value-of select="computer/general/name"/> 
<xsl:text>&#xa;</xsl:text> 
	<xsl:for-each select="computer/general">
		<xsl:text>Jamf Pro ID: </xsl:text>
		<xsl:value-of select="id"/>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>Last Enrollment Date UTC: </xsl:text> 
		<xsl:value-of select="last_enrolled_date_utc"/>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>----------------------</xsl:text>
		<xsl:text>&#xa;</xsl:text> 
	</xsl:for-each> 
</xsl:template> 
</xsl:stylesheet>
EOF

checkVariables
checkTokenExpiration
getEnrollmentDate 
invalidateToken
cleanUp 

exit 0
