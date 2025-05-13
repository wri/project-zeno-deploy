# Import existing RDS instance as a data source
data "aws_db_instance" "zeno-db" {
    db_instance_identifier = "zeno-db"
}

# Create an RDS instance for eoapi
resource "aws_db_instance" "eoapi" {
  identifier = "eoapi-${var.environment}"
  engine     = "postgres"
  engine_version = "15.3"
  instance_class = "db.t3.small"

  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = "eoapi"
  username = "eoapi"
  password = var.eoapi_db_password

  vpc_security_group_ids = [aws_security_group.eoapi_db.id]
  db_subnet_group_name   = aws_db_subnet_group.eoapi.name

  backup_retention_period = 7
  skip_final_snapshot    = true

  # Enable PostGIS
  parameter_group_name = aws_db_parameter_group.eoapi_postgres15.name

  tags = {
    Environment = var.environment
    Name        = "eoapi-${var.environment}"
  }
}

# Create parameter group for PostGIS
resource "aws_db_parameter_group" "eoapi_postgres15" {
  family = "postgres15"
  name   = "eoapi-postgres15-${var.environment}"
}

# Security group for RDS
resource "aws_security_group" "eoapi_db" {
  name        = "eoapi-db-${var.environment}"
  description = "Security group for eoapi database"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.cluster_security_group_id]
  }

  tags = {
    Environment = var.environment
    Name        = "eoapi-db-${var.environment}"
  }
}

# DB subnet group
resource "aws_db_subnet_group" "eoapi" {
  name       = "eoapi-${var.environment}"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Environment = var.environment
    Name        = "eoapi-${var.environment}"
  }
}

# Add outputs for the database endpoint and name
output "eoapi_db_endpoint" {
  value = aws_db_instance.eoapi.endpoint
}

output "eoapi_db_name" {
  value = aws_db_instance.eoapi.db_name
}
