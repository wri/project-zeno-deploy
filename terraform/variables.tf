variable "environment" {
  description = "Environment name (staging or production)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
