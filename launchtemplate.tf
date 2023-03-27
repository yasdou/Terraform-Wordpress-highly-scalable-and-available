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

#provide AWS credentials
mkdir /home/ec2-user/.aws
touch /home/ec2-user/.aws/credentials
cat << END > /home/ec2-user/.aws/credentials
[default]
aws_access_key_id=ASIA4VT4N2G6E3K2SP2H
aws_secret_access_key=mTfOVY8WFfA3vS6GdqHWP8EtKuN/VO5mRSmp9WX0
aws_session_token=FwoGZXIvYXdzEGAaDBkOZoS5Lg5hXRVKuiLAARX9cHiCUJi1WfLpEY3MQfjsx82NiN+aMAyPdtqnNzdDM4oV3VLpAf/tWJBNXLm3JECapmSp1r6qcK0tRdpiS3cUoPfdG3ZH4vXnKOwZZZAh5ze8ioHN9OJdB/SPqOjVnn7kI5S8hqS3jOVhJ/BvEANZ8Rzd71W6+tQblldaPUeWM1nftBNWgt0PAO8kLO5xRbw4WQKZcTuO4OlxqIdiU3UePUjhXtPGQMt180jN+9/5t5Yu+cQSX/4oopsC4m/3+Sj6/oShBjItuJvWiQvdoQq75sHSPcSwbHdydrjBO4uMhbDjyAT+ongrRZ7q/godfbLacfyD 
END
touch /home/ec2-user/.aws/config
cat << END > /home/ec2-user/.aws/config
[default]
region = us-west-2
output = json
END

sudo cp /home/ec2-user/wordpress/wp-config-sample.php /home/ec2-user/wordpress/wp-config.php
sudo sed -i "s/database_name_here/DBWordpress/" /home/ec2-user/wordpress/wp-config.php
sudo sed -i "s/username_here/root/" /home/ec2-user/wordpress/wp-config.php
sudo sed -i "s/password_here/12345678/" /home/ec2-user/wordpress/wp-config.php
sudo sed -i "s/localhost/$(aws rds describe-db-instances --filters Name=db-cluster-id,Values=wordpresscluster --query 'DBInstances[0].Endpoint.Address' --output text)/" /home/ec2-user/wordpress/wp-config.php

sudo cp -r /home/ec2-user/wordpress/* /var/www/html/
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