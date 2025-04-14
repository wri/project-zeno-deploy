module "resources" {
    source = "./resources"
    
    environment = var.environment
    aws_region      = var.aws_region
}