#!/bin/bash
sudo apt-get update
sudo apt-get install -y nginx
echo "Hello siham congratulation this is your first server!" | sudo tee /var/www/html/index.html
sudo systemctl start nginx
sudo systemctl enable nginx