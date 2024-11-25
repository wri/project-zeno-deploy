terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.16"
    }
  }
}