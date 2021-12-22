#!/bin/bash

# Enter your credentials that has API access to your Jamf Pro Server
#Add API credentials
username="apiUser"
password="apiPassword"
URL="https://server.jamfcloud.com/JSSResource"

# Enter the credentials for the new user you would like to create
newUser=""
newPass=""

curl -su $username:$password -H "content-type: application/xml" $URL/JSSResource/accounts/userid/0 -X POST -d "<account><name>$newUser</name><enabled>Enabled</enabled><privilege_set>Administrator</privilege_set><password>$newPass</password></account>"

exit
