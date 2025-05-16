module "resources" {
    source = "./resources"
    
    environment = var.environment
    aws_region = var.aws_region
    eoapi_db_password = var.eoapi_db_password
}

