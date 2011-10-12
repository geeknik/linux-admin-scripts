#/usr/bin/sh
# Copy files from one host to a group of hosts.
# I'm not the original author. Credit goes to someone named avronius.

# SOURCE FILE
SOURCE=$1
# TARGET DIRECTORY/FILE
TARGET=$2
# FILE CONTAINING LIST OF HOSTS
HOSTS=$3
# SSH KEY
ID=$4

if [ -f $SOURCE ]
then
   printf "File found, preparing to transfer\n"
   while read server
   do
      scp -i $ID -p $SOURCE ${server}:$TARGET
   done < $HOSTS
else
   printf "File \"$SOURCE\" not found\n"
   exit 0
fi
exit 0
