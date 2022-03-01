#!/bin/bash

# This script will pass the username from the mobile devices mobile record into a separate EA field.

#Add API credentials
username="apiUsername"
password="apiPassword"
URL="https://jamf.pro.com"

encodedCredentials=$( printf "${username}:${password}" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )

# generate an auth token
authToken=$( /usr/bin/curl "${URL}/uapi/auth/tokens" \
--silent \
--request POST \
--header "Authorization: Basic ${encodedCredentials}" )

# parse authToken for token, omit expiration
token=$( /usr/bin/awk -F \" '{ print $4 }' <<< "$authToken" | /usr/bin/xargs )

#Get
# Enter the EA ID number that you would like to populate
EA="5"

ids+=($(curl -s -H "accept: text/xml" -H "authorization: Bearer ${token}" -S ${URL}/JSSResource/mobiledevices -X GET | xmllint --format - | awk -F'>|<' '/<id>/{print $3}' | sort -n))

for id in "${ids[@]}"; do
	deviceUser=$(curl -s -H "accept: text/xml" -H "authorization: Bearer ${token}" -S ${URL}/JSSResource/mobiledevices/id/${id} -X GET | xmllint --xpath "/mobile_device/location/username/text()" -)
	if [[ ! -z ${deviceUser} ]];then
		curl -s -H "content-type: text/xml" -H "authorization: Bearer ${token}" -S ${URL}/JSSResource/mobiledevices/id/${id} -X PUT -d "<mobile_device><extension_attributes><extension_attribute><id>${EA}</id><value>${deviceUser}</value></extension_attribute></extension_attributes></mobile_device>"
	fi
done

exit 0
