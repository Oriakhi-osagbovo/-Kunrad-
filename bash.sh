#!/bin/bash

# Set the variables for VM names and IP addresses
MASTER_VM="master"
SLAVE_VM="slave"
MASTER_IP="192.168.33.10"
SLAVE_IP="192.168.33.11"
USER_1="AltSchool" 
MYSQL_PASSWORD="Hoosars"
MYSQL_USER="AltSchool.Osas"
MYSQL_USER_PASSWORD="Hoosars001"

# Initialize Vagrant environment
vagrant init generic/ubuntu2204

# Create the Master VM
vagrant up $MASTER_VM --provider virtualbox

# Create the Slave VM
vagrant up $SLAVE_VM --provider virtualbox

# Configure Master as control system
echo "Configuring Master as control system"
vagrant ssh $MASTER_VM -c "echo '<?php phpinfo(); ?>' | sudo tee /var/www/html/index.php"
vagrant ssh $MASTER_VM -c "sudo systemctl enable apache2"
vagrant ssh $MASTER_VM -c "sudo systemctl start apache2"

# Connect Slave to Master for management
echo "Connecting Slave to Master for management"
vagrant ssh $SLAVE_VM -c "sudo sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf"
vagrant ssh $SLAVE_VM -c "sudo systemctl enable apache2"
vagrant ssh $SLAVE_VM -c "sudo systemctl start apache2"

# Create user AltSchool on Master
echo "Creating user AltSchool on Master"
vagrant ssh $MASTER_VM -c "sudo adduser $USER_1"

# Grant AltSchool user root (superuser) privileges
echo "Granting superuser privileges to AltSchool"
vagrant ssh $MASTER_VM -c "sudo usermod -aG sudo $USER_1"

# Configure SSH key-based authentication from Master to Slave
echo "Configuring SSH key-based authentication from Master to Slave"
vagrant ssh $MASTER_VM -c "sudo su - $USER_1 -c 'ssh-keygen -t rsa -b 2048 -N \"\" -f ~/.ssh/id_rsa'"
vagrant ssh $MASTER_VM -c "sudo su - $USER_1 -c 'ssh-copy-id $USER_1@$SLAVE_IP'"

# Copy contents of /mnt/AltSchool from Master to Slave
echo "Copying contents from Master to Slave"
vagrant ssh $MASTER_VM -c "sudo su - $USER_1 -c 'rsync -avz /mnt/AltSchool/ $USER1@$SLAVE_IP:/mnt/AltSchool/slave/'"

# Display overview of currently running processes on Master
echo "Overview of currently running processes on Master:"
vagrant ssh $MASTER_VM -c "ps aux"

# Install LAMP stack on Master
echo "Installing LAMP stack on Master"
vagrant ssh $MASTER_VM -c "sudo apt update"
vagrant ssh $MASTER_VM -c "sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql"

# Install LAMP stack on Slave
echo "Installing LAMP stack on Slave"
vagrant ssh $SLAVE_VM -c "sudo apt update"
vagrant ssh $SLAVE_VM -c "sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql"

# Configure Apache to start on boot and start it
echo "Configuring Apache on Master"
vagrant ssh $MASTER_VM -c "sudo systemctl enable apache2"
vagrant ssh $MASTER_VM -c "sudo systemctl start apache2"

# Configure Apache to start on boot and start it
echo "Configuring Apache on Slave"
vagrant ssh $SLAVE_VM -c "sudo systemctl enable apache2"
vagrant ssh $SLAVE_VM -c "sudo systemctl start apache2"

# Secure MySQL installation on Master
echo "Securing MySQL installation on Master"
vagrant ssh $MASTER_VM -c "sudo mysql_secure_installation"

# Initialize MySQL on Master with default user and password
echo "Initializing MySQL on Master with default user and password"
vagrant ssh $MASTER_VM -c "sudo mysql -uroot -p$MYSQL_PASSWORD -e \"CREATE USER '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_USER_PASSWORD';\""
vagrant ssh $MASTER_VM -c "sudo mysql -uroot -p$MYSQL_PASSWORD -e \"GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@'localhost' WITH GRANT OPTION;\""
vagrant ssh $MASTER_VM -c "sudo mysql -uroot -p$MYSQL_PASSWORD -e \"FLUSH PRIVILEGES;\""

# Secure MySQL installation on Slave
echo "Securing MySQL installation on Slave"
vagrant ssh $SLAVE_VM -c "sudo mysql_secure_installation"

# Initialize MySQL on Slave with default user and password
echo "Initializing MySQL on Slave with default user and password..."
vagrant ssh $SLAVE_VM -c "sudo mysql -uroot -p$MYSQL_PASSWORD -e \"CREATE USER '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_USER_PASSWORD';\""
vagrant ssh $SLAVE_VM -c "sudo mysql -uroot -p$MYSQL_PASSWORD -e \"GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@'localhost' WITH GRANT OPTION;\""
vagrant ssh $SLAVE_VM -c "sudo mysql -uroot -p$MYSQL_PASSWORD -e \"FLUSH PRIVILEGES;\""

# Create a PHP script on Master to test PHP functionality
echo "Creating PHP test script on Master"
vagrant ssh $MASTER_VM -c "echo '<?php phpinfo(); ?>' | sudo tee /var/www/html/phpinfo.php"

# Create a PHP script on Slave to test PHP functionality
echo "Creating PHP test script on Slave"
vagrant ssh $SLAVE_VM -c "echo '<?php phpinfo(); ?>' | sudo tee /var/www/html/phpinfo.php"

echo "Deployment completed successfully."
echo "Master IP: $MASTER_IP"
echo "Slave IP: $SLAVE_IP"
