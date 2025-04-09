module "resources" {
    source = "./resources"
    
    environment = var.environment
    region      = var.aws_region
}