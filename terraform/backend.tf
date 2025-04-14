terraform {
    backend "s3" {
        bucket = "tf-state-project-zeno"
        key = "terraform/state/${terraform.workspace}/terraform.tfstate"
        region = "us-east-1"
    }
}