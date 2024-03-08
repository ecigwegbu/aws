#!/bin/bash

# create the file
aws ec2 describe-instances     --filters "Name=tag:Type,Values=AnsibleNode" \
  --query 'Reservations[*].Instances[*].[PrivateIpAddress, Tags[?Key==`Type`].Value | [0]]' \
  --output text > server_list.txt
# The file you want to process
file="server_list.txt"

# Letter initialization
letter=a

# Read each line
while IFS= read -r line; do
  # Append the current letter and print the line
  echo "${line}${letter}"
  
  # Increment the letter
  letter=$(echo "$letter" | tr "a-yz" "b-za")
done < "$file"

