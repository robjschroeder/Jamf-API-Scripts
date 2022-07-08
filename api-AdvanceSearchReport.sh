#!/bin/sh

# Get the criteria being used my advanced computer searches
#
# Created: 3.31.2022 @ Robjschroeder  
#
# Updated: 4.27.2022 @robjschroeder -- added token invalidation
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

getAdvancedSearchCriteria(){
   ids+=($( curl -s -X GET "${jamfProURL}/JSSResource/advancedcomputersearches" -H "accept: application/xml" -H "Authorization: Bearer ${token}" | xmllint --format - | awk -F'>|<' '/<id>/{print $3}' | sort -n ))
   
   for id in "${ids[@]}"; do
      #######################################
      # Create an XSLT file at /tmp/stylesheet.xslt
      #######################################
      cat << EOF > /tmp/stylesheet.xslt
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:template match="/"> 
<xsl:text>Advance Search Name: </xsl:text>
<xsl:value-of select="advanced_computer_search/name"/> 
<xsl:text>&#xa;</xsl:text>
<xsl:text>&#xa;</xsl:text>
   <xsl:for-each select="advanced_computer_search/criteria/criterion"> 
      <xsl:text>Criteria Used: </xsl:text> 
      <xsl:value-of select="name"/>
      <xsl:text>&#xa;</xsl:text>
      <xsl:text>Operator: </xsl:text>
      <xsl:value-of select="search_type"/>
      <xsl:text>&#xa;</xsl:text>
      <xsl:text>Value: </xsl:text> 
      <xsl:value-of select="value"/>
      <xsl:text>&#xa;</xsl:text>
      <xsl:text>&#xa;</xsl:text>
   </xsl:for-each> 
</xsl:template> 
</xsl:stylesheet>
EOF
      #######################################
      # Request a list of Advanced Computer Searches from the 
      # Jamf Pro Classic API
      # Pass the XML data to xsltproc applying the stylesheet
      #######################################
      
      curl -s -X GET "${jamfProURL}/JSSResource/advancedcomputersearches/id/${id}" -H "accept: application/xml" -H "Authorization: Bearer ${token}" | xsltproc /tmp/stylesheet.xslt -
      echo "---------------------"
      rm -rf /tmp/stylesheet.xslt
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
getAdvancedSearchCriteria 
invalidateToken

exit 0
