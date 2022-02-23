#!/bin/zsh
#
# Script will create a new user Jamf Pro User
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
# Credentials for the new user you would like to create
newUser=""
newPass=""
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
# Empty newUser
if [ -z ${newUser} ]; then
	echo "Please enter the new Jamf Pro username: "
	read $newUser
fi
# Empty newPass
if [ -z ${newPass} ]; then
	echo "Please enter the new Jamf Pro password for ${newUser}: "
	read $newPass
fi

# Create new user
curl -su ${apiUsername}:${apiPassword} -H "content-type: application/xml" ${jssURL}/JSSResource/accounts/userid/0 -X POST -d "<account><name>${newUser}</name><enabled>Enabled</enabled><privilege_set>Administrator</privilege_set><password>${newPass}</password></account>"

exit
