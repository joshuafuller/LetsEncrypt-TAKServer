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

# Function to check .env file for required variables
check_env() {
  if [ -f .env ]; then
    echo -e "${GREEN}Found .env file${NC}"
  else
    echo -e "${RED}Creating .env file${NC}"
    touch .env
    fi
}

# Function to verify that this script is being run on Ubuntu 22.04 LTS and continue if it is
verify_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" = "ubuntu" ] && [ "$VERSION_ID" = "22.04" ]; then
      echo -e "${GREEN}Running on Ubuntu 22.04 LTS${NC}"
    else
      echo -e "${RED}This script is meant to be run on Ubuntu 22.04 LTS${NC}"
      exit 1
    fi
  else
    echo -e "${RED}Unable to determine OS${NC}"
    exit 1
  fi
}

# Function to perform initial system update
update_system() {
  echo -e "${GREEN}Updating system${NC}"
  $SUDO apt update
  $SUDO apt upgrade -y
}




# Function to check if docker and docker-compose are installed and install them if they are not
install_docker() {
  if [ -x "$(command -v docker)" ]; then
    echo -e "${GREEN}Docker is installed${NC}"
  else
    echo -e "${RED}Docker is not installed${NC}"
    echo -e "${GREEN}Installing Docker${NC}"
    $SUDO apt install docker.io -y
    # Check if docker is installed and exit if it is not
    if [ -x "$(command -v docker)" ]; then
      echo -e "${GREEN}Docker installed successfully${NC}"
    else
      echo -e "${RED}Docker unable to be installed${NC}"
      echo -e "${RED}Exiting${NC}"
      exit 1
    fi
  fi

  if [ -x "$(command -v docker-compose)" ]; then
    echo -e "${GREEN}Docker Compose is installed${NC}"
  else
    echo -e "${RED}Docker Compose is not installed${NC}"
    echo -e "${GREEN}Installing Docker Compose${NC}"
    $SUDO apt install docker-compose -y
    # Check if docker-compose is installed and exit if it is not
    if [ -x "$(command -v docker-compose)" ]; then
      echo -e "${GREEN}Docker Compose installed successfully${NC}"
    else
      echo -e "${RED}Docker Compose unable to be installed${NC}"
      echo -e "${RED}Exiting${NC}"
      exit 1
    fi  
  fi
}


# Function to check if certbot is installed and install it if it is not
install_certbot() {
  if [ -x "$(command -v certbot)" ]; then
    echo -e "${GREEN}Certbot is installed${NC}"
  else
    echo -e "${RED}Certbot is not installed${NC}"
    echo -e "${GREEN}Installing Certbot${NC}"
    $SUDO apt install certbot -y
    # Check if certbot is installed and exit if it is not
    if [ -x "$(command -v certbot)" ]; then
      echo -e "${GREEN}Certbot installed successfully${NC}"
    else
      echo -e "${RED}Certbot unable to be installed${NC}"
      echo -e "${RED}Exiting${NC}"
      exit 1
    fi
  fi
}





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


# Function to check if email address is set in .env file and prompt for it if it is not
# Save email address to .env file
check_email() {
  if grep -q "EMAIL=" .env; then
    echo -e "${GREEN}Email address found in .env file${NC}"
    # Read email address from .env file
    EMAIL=$(grep -oP '(?<=EMAIL=).+' .env)
    #Prompt the user to confirm the email address
    echo -e "${GREEN}Email address is set to $EMAIL${NC}"
    read -p "Is this the correct email address? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo -e "${GREEN}Email address confirmed${NC}"
      echo -e "${GREEN}Continuing${NC}"
    else
        # Prompt the user to enter a new email address
        echo -e "${GREEN}Please enter a new email address${NC}"
        read -p "Email Address: " EMAIL
        # Save the email address to the .env file
        echo "EMAIL=$EMAIL" > .env
        echo -e "${GREEN}Email address saved to .env file${NC}"
    fi
    else
        echo -e "${GREEN}Please enter an email address${NC}"
        read -p "Email Address: " EMAIL
        # Save the email address to the .env file
        echo "EMAIL=$EMAIL" > .env
        echo -e "${GREEN}Email address saved to .env file${NC}"
    fi
}


# Function to check if domain name is set in .env file and prompt for it if it is not
# Save domain name to .env file
check_domain() {
  if grep -q "DOMAIN=" .env; then
    echo -e "${GREEN}Domain name found in .env file${NC}"
    # Read domain name from .env file
    DOMAIN=$(grep -oP '(?<=DOMAIN=).+' .env)
    #Prompt the user to confirm the domain name
    echo -e "${GREEN}Domain name is set to $DOMAIN${NC}"
    read -p "Is this the correct domain name? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo -e "${GREEN}Domain name confirmed${NC}"
      echo -e "${GREEN}Continuing${NC}"
    else
        # Prompt the user to enter a new domain name
        echo -e "${GREEN}Please enter a new domain name${NC}"
        read -p "Domain Name: " DOMAIN
        # Save the domain name to the .env file
        echo "DOMAIN=$DOMAIN" >> .env
        echo -e "${GREEN}Domain name saved to .env file${NC}"
    fi
    else
        echo -e "${GREEN}Please enter a domain name${NC}"
        read -p "Domain Name: " DOMAIN
        # Save the domain name to the .env file
        echo "DOMAIN=$DOMAIN" >> .env
        echo -e "${GREEN}Domain name saved to .env file${NC}"
    fi
}



# TODO: Add functionality to check if the domain name is valid



# Function to attempt a dry run of certbot
function dry_run_certbot () {   
    echo -e "${GREEN}Attempting a dry run of certbot${NC}"
    echo -e "${GREEN}This will not generate any certificates${NC}"
    echo -e "${GREEN}This is just to make sure that everything is set up correctly${NC}"
    $SUDO certbot certonly --standalone --preferred-challenges http --email $EMAIL --agree-tos --dry-run -d $DOMAIN
    # Check if the dry run was successful
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Dry run successful${NC}"
        # Prompt the user to confirm that they want to create a certificate in the staging environment
        # or the production environment.
        # Select S for staging or P for production
        echo -e "Do you want to create a certificate in the staging environment or the production environment?"
        echo -e "Select staging if you are testing this script or if you are not sure what to do."
        echo -e "Select production if you are ready to create a certificate in the production environment."
        read -p "Staging or Production (S/P): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            # Call the staging_certbot function
            staging_certbot
        elif [[ $REPLY =~ ^[Pp]$ ]]; then
            # Call the production_certbot function
            production_certbot
        else
            echo -e "${RED}Invalid option${NC}"
            echo -e "${RED}Exiting${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Dry run failed${NC}"
        echo -e "${RED}Exiting${NC}"
        exit 1
    fi  
}




# Function to create a certificate in the staging environment
function staging_certbot() {
    echo -e "${GREEN}Creating certificate in the staging environment${NC}"
    $SUDO certbot certonly --test-cert --standalone --preferred-challenges http --email $EMAIL --agree-tos -d $DOMAIN -n 
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Certificate created successfully${NC}"
        # Display the location of the certificate and its details
        echo -e "${GREEN}Certificate location:${NC}"
        echo -e "${GREEN}/etc/letsencrypt/live/$DOMAIN${NC}"
        echo -e "${GREEN}Certificate details:${NC}"
        echo -e "${GREEN}$(openssl x509 -in /etc/letsencrypt/live/$DOMAIN/fullchain.pem -text -noout)${NC}"
        # Prompt the user to confirm that they want to create a certificate in the production environment
        read -p "Do you want to create a certificate in the production environment? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Call the production_certbot function
            production_certbot
        else
            echo -e "${GREEN}Exiting${NC}"
            exit 0
        fi
    else
        echo -e "${RED}Certificate creation failed${NC}"
        echo -e "${RED}Exiting${NC}"
        exit 1
    fi
}



# Function to create a certificate in the production environment and set up automatic renewal
function production_certbot() {
    echo -e "${GREEN}Creating certificate in the production environment${NC}"
    $SUDO certbot certonly --standalone --preferred-challenges http --email $EMAIL --agree-tos -d $DOMAIN -n 
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Certificate created successfully${NC}"
        # Display the location of the certificate and its details
        echo -e "${GREEN}Certificate location:${NC}"
        echo -e "${GREEN}/etc/letsencrypt/live/$DOMAIN${NC}"
        echo -e "${GREEN}Certificate details:${NC}"
        echo -e "${GREEN}$(openssl x509 -in /etc/letsencrypt/live/$DOMAIN/fullchain.pem -text -noout)${NC}"
        # Prompt the user to confirm that they want to set up automatic renewal
        read -p "Do you want to set up automatic renewal? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Call the setup_automatic_renewal function
            setup_automatic_renewal
        else
            echo -e "${GREEN}Exiting${NC}"
            exit 0
        fi
    else
        echo -e "${RED}Certificate creation failed${NC}"
        echo -e "${RED}Exiting${NC}"
        exit 1
    fi
}

# Function to set up automatic renewal
function setup_automatic_renewal() {
    echo -e "${GREEN}Setting up automatic renewal${NC}"
    # Create a cron job to renew the certificate
    $SUDO crontab -l > mycron
    echo "0 0 * * * $SUDO certbot renew --quiet --no-self-upgrade" >> mycron
    $SUDO crontab mycron
    $SUDO rm mycron
    # Check if the cron job was created successfully
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Automatic renewal set up successfully${NC}"
        echo -e "${GREEN}Exiting${NC}"
        exit 0
    else
        echo -e "${RED}Automatic renewal set up failed${NC}"
        echo -e "${RED}Exiting${NC}"
        exit 1
    fi
}

# Function to detect architecture, ARM vs AMD64
function detect_architecture() {
# TODO: Add functionality to detect architecture, ARM vs AMD64
}

# Function to check if required ports are being used by other services and prompt the user to stop them
# Ports: 80,443,5432,8089,8443,8444,8446,9000,9001
function check_ports() {
 required_ports=(80 443 5432 8089 8443 8444 8446 9000 9001)
 # Loop through the required ports, detect which are in use and prompt the user to kill the processes
    for port in "${required_ports[@]}"; do
    if [ $(netstat -tulpn | grep :$port | wc -l) -gt 0 ]; then
    echo -e "${RED}Port $port is in use by the following process:${NC}"
    echo -e "${RED}$(netstat -tulpn | grep :$port)${NC}"
    echo -e "${RED}Would you like to kill the process?${NC}"
    read -p "Kill process? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Loop through the processes and kill them while displaying the status of each process
        for process in $(netstat -tulpn | grep :$port | awk '{print $7}' | awk -F"/" '{print $1}'); do
            echo -e "${GREEN}Killing process $process${NC}"
            $SUDO kill -9 $process
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Process $process killed successfully${NC}"
            else
                echo -e "${RED}Process $process failed to kill${NC}"
                echo -e "${RED}Exiting${NC}"
                exit 1
            fi
        done
    else
        echo -e "${RED}Exiting${NC}"
        exit 1
    fi
    fi
    done
}

# Function to Check if the folder "tak" exists after previous install or attempt and remove it or leave it for the user to decide
function check_tak_folder() {
    if [ -d "$TAK_FOLDER" ]; then
        echo -e "${RED}The folder $TAK_FOLDER already exists${NC}"
        echo -e "${RED}Would you like to remove it?${NC}"
        read -p "Remove folder? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}Removing folder $TAK_FOLDER${NC}"
            $SUDO rm -rf $TAK_FOLDER
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Folder $TAK_FOLDER removed successfully${NC}"
            else
                echo -e "${RED}Folder $TAK_FOLDER failed to remove${NC}"
                echo -e "${RED}Exiting${NC}"
                exit 1
            fi
        else
            echo -e "${RED}Exiting${NC}"
            exit 1
        fi
    fi
} 





# Main program function
function main {
    # Call the check_root function
    check_root
    # Call the check_sudo function
    check_sudo
    # Call the check_env function
    check_env
    # Call the check_email function
    check_email
    # Call the check_domain function
    check_domain
    # Call the dry_run_certbot function
    dry_run_certbot
}

# Call the main function
main
