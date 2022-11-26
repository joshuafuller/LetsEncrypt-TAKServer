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


# Prompt user for their email address if it is not already set
# If the email address is already set, prompt the user to confirm that it is correct
if [ -z "$EMAIL" ]; then
    echo -e "${GREEN}Please enter your email address${NC}"
    read EMAIL
else
    echo -e "${GREEN}Your email address is set to $EMAIL. Is this correct? (y/n)${NC}"
    read CONFIRM_EMAIL
    if [ "$CONFIRM_EMAIL" = "n" ]; then
        echo -e "${GREEN}Please enter your email address${NC}"
        read EMAIL
    fi
fi



# Prompt user for domain name if $DOMAIN is not set
# If $DOMAIN is set then prompt the user to confirm that it is correct
if [ -z "$DOMAIN" ]; then
    echo -e "${GREEN}Please enter your domain name${NC}"
    read DOMAIN
else
    echo -e "${GREEN}Your domain name is set to $DOMAIN. Is this correct? (y/n)${NC}"
    read CONFIRM_DOMAIN
    if [ "$CONFIRM_DOMAIN" = "n" ]; then
        echo -e "${GREEN}Please enter your domain name${NC}"
        read DOMAIN
    fi
fi


# Check if domain name resolves to this server's WAN IP address
echo -e "${GREEN}Checking if domain name resolves to this server's WAN IP address${NC}"
#Use dig to get the WAN IP address of this server
WAN_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
echo -e "${GREEN}WAN IP address is $WAN_IP${NC}"

# Use dig to query OpenDNS for the IP address of the domain name entered by the user
# Make sure that the domain name resolves to the WAN IP address of this server
DOMAIN_IP=$(dig +short $DOMAIN | tail -n 1)
# Display the IP address of the domain name
echo -e "${GREEN}Domain name resolves to $DOMAIN_IP${NC}"

if [ "$DOMAIN_IP" = "$WAN_IP" ]; then
    echo -e "${GREEN}$DOMAIN resolves to this server's WAN IP: $WAN_IP${NC}"
    echo -e "${RED}$DOMAIN does not resolve to this server's WAN IP: $WAN_IP${NC}"
    exit 1
fi

# If the domain name does not resolve to this server's WAN IP address, prompt the user
# to make sure that the domain name is pointing to this server's WAN IP address
# If the user wants to continue, the script will continue
# If the user does not want to continue, the script will exit
if [ "$WAN_IP" != "$DOMAIN_IP" ]; then
    echo -e "${RED}The domain name resolves to $DOMAIN_IP, which does not match $WAN_IP${NC}"
    echo -e "${RED}Please make sure that the domain name is pointing to this server's WAN IP address${NC}"
    echo -e "${RED}Do you want to continue? (y/n)${NC}"
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
    echo -e "${GREEN}LetsEncrypt dry run was successful${NC}"
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

