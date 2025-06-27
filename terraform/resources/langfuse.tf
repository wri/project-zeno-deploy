# S3 Bucket for current environment
resource "aws_s3_bucket" "langfuse" {
  bucket = "langfuse-${var.environment}-bucket"
}

# IAM user for Langfuse
resource "aws_iam_user" "langfuse" {
  name = "langfuse-${var.environment}-s3-user"
}

# Bucket policy
resource "aws_iam_user_policy" "langfuse" {
  name = "langfuse-${var.environment}-policy"
  user = aws_iam_user.langfuse.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.langfuse.arn,
          "${aws_s3_bucket.langfuse.arn}/*"
        ]
      }
    ]
  })
}

# Access key for the IAM user
resource "aws_iam_access_key" "langfuse" {
  user = aws_iam_user.langfuse.name
}

# Kubernetes secret for Langfuse S3 credentials
resource "kubernetes_secret" "langfuse_s3_credentials" {
  metadata {
    name      = "langfuse-s3-credentials"
    namespace = "default"
  }

  data = {
    access_key_id     = aws_iam_access_key.langfuse.id
    secret_access_key = aws_iam_access_key.langfuse.secret
  }
}

# Outputs
output "langfuse_access_key_id" {
  value = aws_iam_access_key.langfuse.id
}

output "langfuse_secret_key" {
  value     = aws_iam_access_key.langfuse.secret
  sensitive = true
}
