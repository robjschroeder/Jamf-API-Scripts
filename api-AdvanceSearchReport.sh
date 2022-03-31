#!/bin/sh

# Get the criteria being used my advnaced computer searches
#
# Created: 3.31.2022 @ Robjschroeder  

# Variables

# Add API credentials
username="apiUsername"
password="apiPassword"
URL="https://server.jamfcloud.com"

encodedCredentials=$( printf "${username}:${password}" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )

# Generate an auth token
authToken=$( /usr/bin/curl "${URL}/uapi/auth/tokens" \
--silent \
--request POST \
--header "Authorization: Basic ${encodedCredentials}" 
)

# Parse authToken for token, omit expiration
token=$( /usr/bin/awk -F \" '{ print $4 }' <<< "${authToken}" | /usr/bin/xargs )

ids+=($( curl -s -X GET "${URL}/JSSResource/advancedcomputersearches" -H "accept: application/xml" -H "Authorization: Bearer ${token}" | xmllint --format - | awk -F'>|<' '/<id>/{print $3}' | sort -n ))

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
   
   curl -s -X GET "${URL}/JSSResource/advancedcomputersearches/id/${id}" -H "accept: application/xml" -H "Authorization: Bearer ${token}" | xsltproc /tmp/stylesheet.xslt -
   echo "---------------------"
   rm -rf /tmp/stylesheet.xslt
done
