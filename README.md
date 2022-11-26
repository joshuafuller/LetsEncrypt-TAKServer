# LetsEncrpyt-TAKServer

This is not currently ready for production use. It is a work in progress.

This repo contains scripts to help you setup a TAK server with LetsEncrypt SSL certificates.

To install this on a fresh Ubuntu 22.04 server, run the following commands:

``` curl -sL https://raw.githubusercontent.com/joshuafuller/LetsEncrypt-TAKServer/master/setup.sh | sudo -E bash - ``` 

## What does this do?

- # Installs the prerequisites
- Docker, Docker Compose, and Certbot

- # Setup LetsEncrypt
- Installs LetsEncrypt and prompts the user for their email address and domain name.
- Tests the domain name to make sure it is pointing to the server.
- Performs a dry run of the LetsEncrypt certificate generation.
- If the dry run is successful, it will give you the option to test in the staging environment if you choose to test the certificate before going live.
- It will then create production certificates and setup a cron job to renew them every 3 months.

# Setup TAK Server
- Allows the users to select if they want to use their own TAK Server docker image or pull the source from the TAK Server repo and build it.
- If the user chooses to use their own image, it will prompt them for a method to pull the image to the server. (SCP, HTTPS Upload, or other methods)

# Secure Web Server (Optional)
- Allows the user to setup a secure web server to upload images to the TAK Server aswell as download certificates and data packages.
- You can generate a username and password for authentication.
- Display QR codes for one time use to authenticate to the web server.


## Exploring possible features
- Using transfer.sh to upload images to the TAK Server
- Using a web server to upload images to the TAK Server
- Using a web server to download certificates and data packages
