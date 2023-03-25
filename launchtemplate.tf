# Launch Template Resource
resource "aws_launch_template" "launchtemplate" {
  name = "launchtemplate"
  image_id = var.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.WordpressSGprivateinstances.id]
  key_name = var.ami_key_pair_name
  user_data = base64encode(<<EOF
#!/bin/bash
HOMEDIR=/home/ec2-user

yum update -y

amazon-linux-extras install lamp-mariadb10.2-php7.2

echo Installing packages...
echo Please ignore messages regarding SELinux...
yum install -y \
httpd \
mariadb-server \
php \
php-gd \
php-mbstring \
php-mysqlnd \
php-xml \
php-xmlrpc

MYSQL_ROOT_PASSWORD=pass
echo $MYSQL_ROOT_PASSWORD > $HOMEDIR/MYSQL_ROOT_PASSWORD
chown ec2-user $HOMEDIR/MYSQL_ROOT_PASSWORD

echo Starting database service...
sudo systemctl start mariadb
sudo systemctl enable mariadb

echo Setting up basic database security...
mysql -u root <<DB_SEC
UPDATE mysql.user SET Password=PASSWORD('$MYSQL_ROOT_PASSWORD') WHERE User='root';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
FLUSH PRIVILEGES;
DB_SEC

echo Configuring Apache...
usermod -a -G apache ec2-user
chown -R ec2-user:apache /var/www
chmod 2775 /var/www && find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;

echo Starting Apache...
sudo systemctl start httpd
sudo systemctl enable httpd

echo installing wordpress and creating mysqluser
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz -C /home/ec2-user
sudo systemctl start mariadb

DB_USER="wordpressuser"
DB_PASSWORD="pass"
DB_NAME="wordpressdb"

# create user and grant privileges
mysql -u root -p$MYSQL_ROOT_PASSWORD <<DB_USER
CREATE DATABASE $DB_NAME;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
DB_USER

cp /home/ec2-user/wordpress/wp-config-sample.php /home/ec2-user/wordpress/wp-config.php
sed -i "s/database_name_here/wordpressdb/" /home/ec2-user/wordpress/wp-config.php
sed -i "s/username_here/wordpressuser/" /home/ec2-user/wordpress/wp-config.php
sed -i "s/password_here/pass/" /home/ec2-user/wordpress/wp-config.php

cp -r /home/ec2-user/wordpress/* /var/www/html/
sudo systemctl restart httpd
EOF
)
  monitoring {
    enabled = true
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "launchtemplate"
    }
  }
}
