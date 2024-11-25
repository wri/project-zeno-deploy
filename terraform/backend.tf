terraform {
    backend "s3" {
        bucket = "tf-state-project-zeno"
        key = "terraform/state/prod/terraform.tfstate"
        region = "us-east-1"
    }
}