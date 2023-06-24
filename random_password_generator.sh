#!/bin/bash
DEFAULT_PASS_LEN=30
DEFAULT_CHAR_SET='A-Za-z0-9!@#$%^&*()-=_+[]{}|;:,.<>?/~`'
read -p "Enter desired password length (default is $DEFAULT_PASS_LEN): " PASS_LEN
PASS_LEN=${PASS_LEN:-$DEFAULT_PASS_LEN}
read -p "Enter desired character set (default is $DEFAULT_CHAR_SET): " CHAR_SET
CHAR_SET=${CHAR_SET:-$DEFAULT_CHAR_SET}
PASSWORD=$(head /dev/urandom | tr -dc "$CHAR_SET" | fold -w ${PASS_LEN} | head -n 1)
PASSWORD=$(echo $PASSWORD | sed 's/\(.\)/\1\n/g' | awk '{ if (rand() > 0.5) print toupper($0); else print tolower($0); }' ORS='')
echo "Your random password is: $PASSWORD" # generate robust random password
