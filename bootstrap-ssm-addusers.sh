#!/bin/bash

# This script bootstraps AWS ssm function when creating EC2 instance based on a RHEL AMI
# and creates additional users based on a list of user names
# The users will connect to the EC2 instance from putty using the same
# private key used by the default user ec2-user

# Usage: When creating an EC2 or creating/updating a Launch template, copy and paste this
# script into the "user data" text box in the "Advanced details" section of the console.

# Install, Start and Enable Amazon SSM Agent (if using RHEL AMI)
if [[ -n $(grep -i 'Red Hat Enterprise Linux' /etc/os-release) ]]; then
  dnf install -y https://s3.us-east-1.amazonaws.com/amazon-ssm-us-east-1/latest/linux_amd64/amazon-ssm-agent.rpm
   systemctl enable --now amazon-ssm-agent
fi

# create additional users and enable ssh authentication with the existing key-pair
for user in elias richard donald; do  # do this for each of the three named users
  if [[ -z $(getent passwd ${user}) ]]; then  # but only if they don't already exist
    sudo useradd ${user}
    sudo mkdir /home/${user}/.ssh
    sudo cp -R /home/ec2-user/.ssh/authorized_keys\
      /home/${user}/.ssh/authorized_keys
    sudo chown -R ${user}:${user} /home/${user}/.ssh
    sudo chmod 700 /home/${user}/.ssh
    sudo chmod 600 /home/${user}/.ssh/authorized_keys
  fi
done

# (c) 2024 Unix Training Academy. All Rights Reserved.
# Author: Elias Igwegbu, MNSE, MBA, SWE-ALX/Holberton, RHCSA
