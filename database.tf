resource "aws_rds_cluster" "RDSWP" {
  cluster_identifier = "wordpresscluster"
  engine             = "aurora-mysql"
  engine_version     = "5.7.mysql_aurora.2.11.1"
  database_name      = var.DBName
  master_username    = var.DBUser
  master_password    = var.DBPassword
  vpc_security_group_ids    = [aws_security_group.allow_aurora_access.id]
  db_subnet_group_name      = aws_db_subnet_group.DBSubnetGroup.id
  skip_final_snapshot       = true
  final_snapshot_identifier = "aurora-final-snapshot"

  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }
  tags = {
    Name = "auroracluster-Wordpressdb"
  }
}

resource "aws_rds_cluster_instance" "clusterinstance" {
  count              = 2
  identifier         = "clusterinstance-${count.index}"
  cluster_identifier = aws_rds_cluster.RDSWP.id
  instance_class     = "db.t3.small"
  engine             = "aurora-mysql"
  availability_zone  = "us-west-2${count.index == 0 ? "a" : "b"}"

  tags = {
    Name = "auroracluster-db-instance${count.index + 1}"
  }
}

resource "aws_rds_cluster_endpoint" "RDSendpoint" {
  cluster_identifier          = aws_rds_cluster.RDSWP.id
  cluster_endpoint_identifier = "writer"
  custom_endpoint_type        = "ANY"
}