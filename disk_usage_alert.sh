#!/bin/bash

# Set the threshold percentage for disk usage
THRESHOLD=80

# Set the email address to receive the alert
EMAIL="admin@example.com"

# Get the current disk usage percentage
USAGE=$(df --output=pcent / | tail -1 | tr -dc '0-9')

# Check if the usage exceeds the threshold
if [ $USAGE -gt $THRESHOLD ]; then
  # Send an email alert
  echo "Disk usage on $(hostname) is at ${USAGE}%." | mail -s "Disk Usage Alert" $EMAIL
fi
