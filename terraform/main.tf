module "resources" {
    source = "./resources"
    
    environment = var.environment
    aws_region = var.aws_region
    eoapi_db_password = var.eoapi_db_password
}

output "eoapi_db_endpoint" {
    description = "The endpoint of the eoapi RDS instance"
    value = module.resources.eoapi_db_endpoint
}
