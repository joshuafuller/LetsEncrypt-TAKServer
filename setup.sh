# 
# This script is meant to be run on a fresh install of Ubuntu 22.04 LTS
# 
# This script will install the TAK Server and Database containers

# This script will configure LetsEncrypt to automatically renew the SSL certificate
# and will configure the TAK Server to automatically restart if it crashes
# 

# TODO: Add functionality to allow uploading to TAK Docker Image through secure HTTPS
# connection using LetsEncrypt certificates and authentication


# Detect if sudo is required and adjust the command accordingly
if [ "$EUID" -ne 0 ]
  then SUDO=sudo
  else
    SUDO=
fi

# Set colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Verify that this script is being run on Ubuntu 22.04 LTS and continue if it is
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" = "ubuntu" ] && [ "$VERSION_ID" = "22.04" ]; then
        echo -e "${GREEN}This script is being run on Ubuntu 22.04 LTS${NC}"
    else
        echo -e "${RED}This script is not being run on Ubuntu 22.04 LTS${NC}"
        exit 1
    fi
else
    echo -e "${RED}This script is not being run on Ubuntu 22.04 LTS${NC}"
    exit 1
fi

# Install docker and docker-compose
echo -e "${GREEN}Installing docker and docker-compose${NC}"
$SUDO apt-get update
$SUDO apt-get install -y docker.io docker-compose


# Install certbot
echo -e "${GREEN}Installing certbot${NC}"
$SUDO apt-get install -y certbot

# Prompt user for email address
echo -e "${GREEN}Please enter an email address for LetsEncrypt${NC}"
read EMAIL

# Prompt user for domain name
echo -e "${GREEN}Please enter a domain name for the TAK Server${NC}"
read DOMAIN

# Check if domain name resolves to this server's WAN IP address
echo -e "${GREEN}Checking if domain name resolves to this server's WAN IP address${NC}"
#Use dig to get the WAN IP address of this server
WAN_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
DOMAIN_IP=$(dig +short $DOMAIN)
if [ "$WAN_IP" = "$DOMAIN_IP" ]; then
    echo -e "${GREEN}Domain name resolves to this server's WAN IP address${NC}"
else
    echo -e "${RED}Domain name does not resolve to this server's WAN IP address${NC}"
    echo -e "${RED}Please check you have entered the correct domain name${NC}"
    echo -e "${RED}and that the domain name is pointing to this server's WAN IP address${NC}"
    # Prompt user to continue anyway
    echo -e "${GREEN}Do you want to continue anyway?${NC}"
    read -p "Enter y to continue or n to exit: " CONTINUE
    if [ "$CONTINUE" = "n" ]; then
        exit 1
    fi
fi

# Setup LetsEncrypt to do a dry run and get a certificate
echo -e "${GREEN}Getting LetsEncrypt certificate${NC}"
$SUDO certbot certonly --standalone --preferred-challenges http --email $EMAIL --agree-tos --no-eff-email --dry-run -d $DOMAIN

