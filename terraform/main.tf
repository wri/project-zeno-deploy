module "resources" {
    source = "./resources"
    
    environment = var.environment
    aws_region = var.aws_region
    eoapi_db_password = var.eoapi_db_password
}

# Expose cluster autoscaler IAM role ARN from resources module
output "cluster_autoscaler_iam_role_arn" {
  description = "ARN of the IAM role for cluster autoscaler"
  value       = module.resources.cluster_autoscaler_iam_role_arn
}

