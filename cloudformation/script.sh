#!/bin/bash

echo -n "configuring the servers..."
# create the file
aws ec2 describe-instances --filters "Name=tag:Type,Values=AnsibleNode" \
  "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[PrivateIpAddress, Tags[?Key==`AliasName`].Value | [0]]' \
  --output text > server_list.txt
# The file you want to process
file="server_list.txt"

# Letter initialization; the letter will be incremented for subsequent servers
letter=a

echo -n > hosts-file
# Read each line
while IFS= read -r line; do
  # Check if line contains 'workstation'
  if echo "${line}" | grep -q 'workstation'; then
    # extract the line item to the hosts-file
    echo "${line} workstation.lab.example.com" | sed "s/\s\+/    /g" >> hosts-file
  elif echo "${line}" | grep -q 'server'; then
    # Append the current letter and print the line
    echo "${line}${letter} server${letter}.lab.example.com" | sed "s/\s\+/    /g" >> hosts-file
    # Re-label the Instance Name Tags on the console. First, retrieve the ip address
    myip=$(echo ${line} | cut -d' ' -f 1)
    # retrieve the instance id based on the private ip address:
    instance_id=$(aws ec2 describe-instances \
      --filters "Name=private-ip-address,Values=${myip}" \
      --query 'Reservations[*].Instances[*].InstanceId' \
      --output text)
    # set the instance Name tag based on the just retrieved instance id
    aws ec2 create-tags --resources "${instance_id}" --tags Key=Name,Value=server"${letter}"
    # Increment the letter
    letter=$(echo "$letter" | tr "a-yz" "b-za")
  fi
done < "$file"

# now login to each server and set hostname and update /etc/hosts:
file="hosts-file"

# Open the file with file descriptor 3
exec 3< "$file"
exec 3< "$file"

mkdir -p /home/ansible/.config/  # we will track processed nodes in here
# Read each line using file descriptor 3
while IFS= read -r line <&3; do
  # get the ip address and hostname
  myip=$(echo "${line}" | cut -d' ' -f1)
  myhostname=$(echo "${line}" | cut -d' ' -f9)
  # Only process the server once
  if [[ ! -f /home/ansible/.config/processed_${myip} ]]; then
    # echo "processing ${myhostname}..."
    # Set the hostname
    ssh -n -q -o StrictHostKeyChecking=no "${myip}" sudo hostnamectl set-hostname "${myhostname}"
    # copy the hosts-file created above to /etc/hosts, via /tmp; cleanup after the job
    scp -q -o StrictHostKeyChecking=no hosts-file "${myip}":/tmp/hosts-file.123456 >> /tmp/scp_log_123456.txt 2>&1
    ssh -n -q -o StrictHostKeyChecking=no "${myip}" 'cat /tmp/hosts-file.123456 | sudo tee -a /etc/hosts' >> /tmp/ssh_log_123456.txt 2>&1
    ssh -n -q -o StrictHostKeyChecking=no "${myip}" 'rm -f /tmp/hosts-file.123456'
    touch "/home/ansible/.config/processed_${myip}"
  fi
  echo -n \.
done

# Close the file descriptor
exec 3<&-

# cleanup
rm -f server_list.txt
rm -f hosts-file
echo
echo "Done."
