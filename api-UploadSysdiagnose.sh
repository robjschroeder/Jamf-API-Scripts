#!/bin/bash

# Title:  sysdiagnoseSelfService.sh
# Created By: Keith Mitnick - HCS Technology Group
# Version: 1
# Creation Date: 08-22-2021
# Last Modified Date:
# Tested on OS Version:  macOS BigSur 11.5.2
###############################################################################################################################
# This script will do the following:
# 1.  Remove all sysdiagnose files found in /private/var/tmp before running main script.
# 2.  Run a sysdiagnose command to gather all logs into a zip file
# 3.  Upload the sysdiagnose file to the computer record on the Jamf Pro Server.
###############################################################################################################################
# NOTE: THIS SCRIPT IS PROVIDED AS IS WITHOUT WARRANTY OF ANY KIND.  USE IT AT YOUR OWN RISK.
###############################################################################################################################

###############################################################################################################################
# Cleanup - Remove all sysdiagnose files found in /private/var/tmp before running main script.
/bin/rm -rf /private/var/tmp/sysdiagnose*

###############################################################################################################################
#Run the sysdiagnose in the background without user interaction
/usr/bin/sysdiagnose -u &

###############################################################################################################################
#Wait until the sysdiagnose file is located in /private/var/tmp before continuing with the script

until [ -f /private/var/tmp/sysdiagnose* ]
do
	sleep 5
done
echo "Sysdiagnose file found. Uploading the sysdiagnose file to the Jamf Pro Server....."

###############################################################################################################################
#Prepare to upload the sysdiagnose file to the jamf pro server via the API - This requires a user with proper API credentials.

#Jamf Pro Server URL
jssUrl=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url | sed s'/.$//')

#API User and Password are stored and defined in the jamf pro server in the script parameters $4 and $5
apiUser="$4"
apiPass="$5"

#Get the serial number of the mac running this script.
serialNumber=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $4}')

#Use the API to get Computer ID
computerID=$(curl -su "$apiUser":"$apiPass" -H "Accept: application/xml" "$jssUrl"/JSSResource/computers/serialnumber/"$serialNumber" | xmllint --xpath 'computer/general/id/text()' -)

#File to upload - This is the newly created zipped sysdiagnose file in /prvate/var/tmp
fileToUpload=$(/bin/ls /private/var/tmp | grep sysdiagnose)

#command to upload to Jamf Pro Server
curl -sfku "$apiUser":"$apiPass" "$jssUrl"/JSSResource/fileuploads/computers/id/"$computerID" -F name=@/private/var/tmp/"$fileToUpload" -X POST

#Check to status of the file upload
uploadStatus=$?

#Use Jamf Helper to display message to user
if [ $uploadStatus != 0 ]; then
	/usr/local/bin/jamf displayMessage -message "The sysdiagnose file FAILED to upload successfully to your computer record on the Jamf Pro Server.  Please contact the IT Department for assistance."
else
	/usr/local/bin/jamf displayMessage -message "The sysdiagnose file was uploaded successfully to your computer record on the Jamf Pro Server."
fi

#Use upload exit status to exit the script with 0 for success or 1 for failure.

if [ $uploadStatus != 0 ]; then
	exit 1
else
	exit 0
fi 
