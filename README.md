# Terraform-Wordpress-highly-scalable-and-available
Template to launch a Wordpress server with a load balancer and auto scaling group and a RDS Aurora Instance with Read Replicas
The Bastion Host is reachable from the Mission Ip Adress that launched the script only. From there you can reach the other EC2 instances

![Diagram](wordpress_rds_elb_asg.drawio.svg)