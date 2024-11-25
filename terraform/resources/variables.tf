variable "environment" {
    description = "The environment to deploy to"
    default = "production"
}

variable "region" {
    description = "The region to deploy to"
    default = "us-east-1"
}

locals {
    stack_id = "zeno"
    prefix = "${local.stack_id}-${var.environment}"
    cluster_name = "${local.prefix}-cluster"

    tags = {
        Project = "zeno"
    }
}