#!/bin/bash

read -p "Enter username: " USERNAME
read -s -p "Enter password: " PASSWORD
echo

if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
  echo "Username and password cannot be empty."
  exit 1
fi

# Get public IP
PUBLIC_IP=$(curl -s ifconfig.me)

# Update and install squid
sudo apt update && sudo apt install squid -y curl

# Start and enable squid service
sudo systemctl start squid
sudo systemctl enable squid

# Install Apache utilities for password management
sudo apt-get install apache2-utils -y

# Create a password file and add a user
sudo htpasswd -b -c /etc/squid/passwd "$USERNAME" "$PASSWORD"

# Backup the original squid configuration file
sudo cp /etc/squid/squid.conf /etc/squid/squid.conf.backup

# Write the configuration to the squid.conf file
sudo bash -c 'cat <<EOL > /etc/squid/squid.conf
http_port 3128

acl all src 0.0.0.0/0

auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 5
auth_param basic realm Squid proxy-caching web server
auth_param basic credentialsttl 2 hours
auth_param basic casesensitive on

acl authenticated proxy_auth REQUIRED
http_access allow authenticated
http_access deny all
EOL'

# Restart the squid service to apply changes
sudo systemctl restart squid

echo ""
echo "=================================="
echo "        PROXY CREATED"
echo "=================================="
echo "Proxy URL : $PUBLIC_IP:3128"
echo "Username  : $USERNAME"
echo "Password  : $PASSWORD"
echo "=================================="
