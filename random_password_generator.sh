#!/bin/bash
PASS_LEN=30
PASSWORD=$(head /dev/urandom | tr -dc 'A-Za-z0-9!@#$%^&*()-=_+[]{}|;:,.<>?/~`' | fold -w ${PASS_LEN} | head -n 1)
PASSWORD=$(echo $PASSWORD | sed 's/\(.\)/\1\n/g' | awk '{ if (rand() > 0.5) print toupper($0); else print tolower($0); }' ORS='')
echo "Your random password is: $PASSWORD" # generate random password
