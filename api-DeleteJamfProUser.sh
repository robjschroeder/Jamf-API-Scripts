#!/bin/bash

#Add API credentials
username="apiUser"
password="apiPassword"
URL="https://server.jamfcloud.com"

# Find the id of the account you would like to delete
id=""

# Command to delete the account
curl -su $username:$password $URL/JSSResource/accounts/userid/$id -X DELETE

exit
