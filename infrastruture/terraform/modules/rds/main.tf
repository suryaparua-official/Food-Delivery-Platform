terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name_prefix            = "${var.project_name}-db-subnet-"
  subnet_ids             = var.private_subnet_ids
  skip_final_snapshot    = false

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-db-subnet-${var.environment}"
    }
  )
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier_prefix      = "${var.project_name}-db-"
  allocated_storage      = var.allocated_storage
  storage_type           = var.storage_type
  engine                 = "postgres"
  engine_version         = var.postgres_version
  instance_class         = var.instance_class
  
  db_name                = var.database_name
  username               = var.db_username
  password               = var.db_password
  
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id]
  
  skip_final_snapshot       = var.environment == "dev" ? true : false
  final_snapshot_identifier = var.environment != "dev" ? "${var.project_name}-db-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null
  
  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"
  
  multi_az               = var.multi_az
  publicly_accessible    = false
  
  storage_encrypted      = true
  kms_key_id             = var.kms_key_id
  
  enable_cloudwatch_logs_exports = ["postgresql"]
  
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = 7
  
  enable_iam_database_authentication = true
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-db-${var.environment}"
    }
  )

  depends_on = [aws_db_subnet_group.main]
}

# RDS Parameter Group for optimization
resource "aws_db_parameter_group" "main" {
  name_prefix = "${var.project_name}-db-params-"
  family      = "postgres${var.postgres_version}"

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements,pgaudit"
  }

  parameter {
    name  = "max_connections"
    value = "500"
  }

  parameter {
    name  = "log_statement"
    value = "all"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-db-params-${var.environment}"
    }
  )
}
