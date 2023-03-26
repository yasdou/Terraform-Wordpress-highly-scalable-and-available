resource "aws_rds_cluster" "RDSWP" {
  cluster_identifier = "wordpresscluster"
  engine             = "aurora-mysql"
  engine_version     = "5.7.mysql_aurora.2.11.1"
  database_name      = "WPDatabase"
  master_username    = "root"
  master_password    = "12345678"
  vpc_security_group_ids = [aws_security_group.allow_aurora_access.id]
  db_subnet_group_name = aws_db_subnet_group.DBSubnetGroup.id

  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }
  tags = {
    Name = "auroracluster-Wordpressdb"
  }
}

resource "aws_rds_cluster_instance" "WPRDSCluster" {
  cluster_identifier = aws_rds_cluster.RDSWP.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.RDSWP.engine
  engine_version     = aws_rds_cluster.RDSWP.engine_version
}