#!/bin/bash

# The file you want to process
file="your_file_here.txt"

# Letter initialization
letter=a

# Read each line
while IFS= read -r line; do
  # Append the current letter and print the line
  echo "${line}${letter}"
  
  # Increment the letter
  letter=$(echo "$letter" | tr "a-yz" "b-za")
done < "$file"

