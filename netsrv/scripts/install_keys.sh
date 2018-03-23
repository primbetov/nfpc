#!/bin/bash
keys[0]="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDFChKXmWoquiPb9/672PySge/grKK17JgnDvoXKjQWhm5tkJsFHHXKIw5WKxFK5l87cGP8RfKsa1d08yO/RsIg901LQGDcTlOrohkdWecszQASKyrwls2shprjBemtntBjrmVzvtaPDSdOWgLPu8sEE4/cGGbYLSbami719gVosDg9KPWRORTIVkybqnyFLJvDNY+JyJjU96bkLvSKV0/xBDF95ItW8EFZLBp4lj3PSZQg8w0pphteknPz00lJGayM5kaEF4lOEerY7ZKlq6fzfFWw5qof5s/kgNc9Cf4j+xlm1pwLLfnC5unz/tj7gnDa3ZWpFDU34yXBDBr/GHnb root@test1"
if [ -z "$1" ];then 
  user="root"
else 
  user=$1
fi


# Need to find homedir of user
homedir=$(awk -F ":" '/^root/ {print $6}' /etc/passwd)
keyfile="$homedir/.ssh/authorized_keys"
mkdir -p "$homedir/.ssh"

# Permit root login with sshkey and prohibit login with only password
sed -r -i 's/^PermitRootLogin.*/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config

# Add keys from array
for id in ${!keys[*]}
do
  key=${keys[$id]}
  exist=$(grep "$key" "$keyfile") 
  if [ -z "$exist" ];then
    echo $key >> "$keyfile"
  fi
done
