#!/bin/bash 

#This script will grab all the ids of User objects in Jamf Pro, store them in an array
#loop through that array and send a delete command to the Users api endpoint. 
#Users that have devices assigned to them will not be deleted as the device acts
#as a dependency of their account. Only accounts that do not have a devices associated
#with it will be deleted
#
# Updated: 3.01.2022 @ Robjschroeder  


### Variables ###

#Add API credentials
username="apiUsername"
password="apiPassword"
URL="https://server.jamfcloud.com"


# Sleep options #
# Time to sleep between issuing commands to each device in seconds
commandSleep="1"
# Time to sleep between processing each batch in seconds
batchSleep="5"
## No need to change contents below ##

# Always zero
start=0
# Number of item in the batch
elements=10


# Create array of IDs from our User base in Jamf Pro
ids+=($(curl -su $username:$password -H "accept: text/xml" $URL/JSSResource/users -X GET | xmllint --format - | awk -F'>|<' '/<id>/{print $3}' | sort -n))

for ((i = 0 ; i < ${#ids[@]} ; i++)); do
	id_list=($(echo ${ids[@]:$start:$elements}))
	if ! [  -z "${id_list}" ]; then
		for ((x = 0 ; x < ${#id_list[@]} ; x++)); do
			# Delete the user with ID number
			echo "Sending update command to delete User: ${id_list[$x]}" >> ~/Desktop/UserDelete.txt
			curl -su $username:$password -H "accept: text/xml" $URL/JSSResource/users/id/${id_list[$x]} -X DELETE >> ~/Desktop/UserDelete.txt
			# Time to wait between sending commands to each device
			sleep $commandSleep
		done
		echo "Processing next batch of ${elements}"
		# Time to wait between batches
		sleep $batchSleep
	else
		echo "Finished Processing"
		break
	fi
	(( start=start+${elements} ))
done

exit 0
