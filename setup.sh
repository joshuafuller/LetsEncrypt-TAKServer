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

# Install certbot using apt
echo -e "${GREEN}Installing certbot${NC}"
$SUDO apt-get install -y certbot

# TODO: Add firewall check and make sure that port 80 and 443 are open

# # Check if UFW is currently enabled and make sure that port 80 and 443 are open
# echo -e "${GREEN}Checking if UFW is enabled and opening ports 80 and 443${NC}"
# if [ -f /etc/default/ufw ]; then
#     . /etc/default/ufw
#     if [ "$IPV6" = "yes" ]; then
#         $SUDO ufw allow 80/tcp
#         $SUDO ufw allow 443/tcp
#     else
#         $SUDO ufw allow 80/tcp
#         $SUDO ufw allow 443/tcp
#     fi
# else
#     echo -e "${RED}UFW is not enabled${NC}"
#     exit 1
# fi

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
echo -e "${GREEN}WAN IP address is $WAN_IP${NC}"

# Query openDNS to get the IP address of the domain name
DOMAIN_IP=$(dig +short $DOMAIN @resolver1.opendns.com)
echo -e "${GREEN}Domain IP address is $DOMAIN_IP${NC}"


# If the domain name does not resolve to this server's WAN IP address, prompt the user
# to make sure that the domain name is pointing to this server's WAN IP address
# If the user wants to continue, the script will continue
# If the user does not want to continue, the script will exit
if [ "$WAN_IP" != "$DOMAIN_IP" ]; then
    echo -e "${RED}The domain name does not resolve to this server's WAN IP address${NC}"
    echo -e "${RED}Please make sure that the domain name is pointing to this server's WAN IP address${NC}"
    echo -e "${RED}Do you want to continue anyway? (y/n)${NC}"
    read CONTINUE
    if [ "$CONTINUE" != "y" ]; then
        echo -e "${RED}Exiting script${NC}"
        exit 1
    fi
fi



# Do a dry run of certbot to verify that the dry run is successful
# If successful, continue with the LetsEncrypt setup
echo -e "${GREEN}Running a dry run of certbot to verify that the setup is successful${NC}"
$SUDO certbot certonly --dry-run --standalone -d $DOMAIN -m $EMAIL --agree-tos
if [ $? -eq 0 ]; then
    echo -e "${GREEN}LetsEncrypt setup is successful${NC}"
    # Prompt the user if they would like to attempt to request a production certificate
    echo -e "${GREEN}Would you like to request a production certificate?${NC}"
    read -p "y/n: " PRODUCTION
    if [ "$PRODUCTION" = "y" ]; then
        echo -e "${GREEN}Requesting a production certificate${NC}"
        $SUDO certbot certonly --standalone -d $DOMAIN -m $EMAIL --agree-tos
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Production certificate request was successful${NC}"
        else
            echo -e "${RED}Production certificate request was unsuccessful${NC}"
            echo -e "${RED}Exiting${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}Exiting${NC}"
        exit 1
    fi
else
    echo -e "${RED}LetsEncrypt setup is unsuccessful${NC}"
    echo -e "${RED}Exiting${NC}"
    exit 1
fi

