#!/bin/zsh
#
# Script will generate a bearer token for use
# with JPAPI
#
# Updated: 2.22.2022 @ Robjschroeder                 
#
# Variables
#
# API credentials
apiUsername=""
apiPassword=""
jssURL=""
#
# ID of the account you would like to delete
id=""
#
# Check for input on variables, prompt if empty
#
# Empty Username
if [ -z ${apiUsername} ]; then
	echo "Please enter your Jamf Pro username: "
	read $apiUsername
fi
# Empty Password
if [ -z ${apiPassword} ]; then
	echo "Please enter your Jamf Pro password: "
	read $apiPassword
fi
# Empty jssURL
if [ -z ${jssURL} ]; then
	echo "Please enter your Jamf Pro URL: "
	echo "(ex. https://server.jamfcloud.com)"
	read $jssURL
fi
# Empty id
if [ -z ${id} ]; then
  echo "Please enter the id number of the account you want to delete: "
  read $id
fi

# Command to delete the account
curl -su $username:$password $URL/JSSResource/accounts/userid/$id -X DELETE

exit
