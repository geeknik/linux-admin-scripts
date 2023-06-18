#!/bin/bash

# Set the path to the CSV file
CSV_FILE="users.csv"

# Function to create a user and send a welcome email
create_user_and_send_email() {
  local username="$1"
  local email="$2"

  # Create the user account
  useradd -m "$username"

  # Generate a random password
  password=$(tr -dc A-Za-z0-9 </dev/urandom | head -c8)

  # Set the user's password
  echo "$username:$password" | chpasswd

  # Send a welcome email with the login details
  email_subject="Welcome to the Linux server"
  email_body="Hello $username,\n\nYour account has been created on our Linux server.\n\nUsername: $username\nPassword: $password\n\nPlease change your password after your first login.\n\nBest regards,\nLinux Admin"
  echo -e "$email_body" | mail -s "$email_subject" "$email"

  echo "User $username created and welcome email sent to $email."
}

# Read the CSV file, skip the first line (header), and create users
tail -n +2 $CSV_FILE | while IFS=',' read -r username email; do
  create_user_and_send_email "$username" "$email"
done
