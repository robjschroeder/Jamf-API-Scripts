#!/bin/bash
# This script will pass the username from the mobile devices mobile record into a separate EA field.

#Add API credentials
username="user"
password="pass"
URL="https://server.jamfcloud.com"

# Enter the EA ID number that you would like to populate
EA=""

#Get Token from Jamf Pro
token=$(printf "${username}:${password}" | iconv -t ISO-8859-1 | base64 -i -)



ids+=($(curl -s -H "accept: text/xml" -H "authorization: Basic $token" -S $URL/JSSResource/mobiledevices -X GET | xmllint --format - | awk -F'>|<' '/<id>/{print $3}' | sort -n))

for id in "${ids[@]}"; do
	deviceUser=$(curl -s -H "accept: text/xml" -H "authorization: Basic $token" -S $URL/JSSResource/mobiledevices/id/$id -X GET | xmllint --xpath "/mobile_device/location/username/text()" -)
	if [[ ! -z $deviceUser ]];then
		curl -s -H "content-type: text/xml" -H "authorization: Basic $token" -S $URL/JSSResource/mobiledevices/id/$id -X PUT -d "<mobile_device><extension_attributes><extension_attribute><id>$EA</id><value>$deviceUser</value></extension_attribute></extension_attributes></mobile_device>"
	fi
done
