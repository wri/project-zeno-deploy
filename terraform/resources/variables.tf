variable "environment" {
    description = "The environment to deploy to"
    default = "production"
    type = string
}

variable "aws_region" {
    description = "The region to deploy to"
    default = "us-east-1"
    type = string
}

locals {
    stack_id = "zeno"
    prefix = "${local.stack_id}-${var.environment}"
    cluster_name = "${local.prefix}-cluster"

    tags = {
        Project = "zeno"
    }
}