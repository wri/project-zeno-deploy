module "resources" {
    source = "./resources"
    
    environment = var.environment
    region  = var.region
}