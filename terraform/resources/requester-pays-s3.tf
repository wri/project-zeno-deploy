# IAM user for Requester Pays S3 access
resource "aws_iam_user" "requester_pays" {
  name = "eoapi-requester-pays-${var.environment}-user"
}

# Policy for requester pays S3 access
resource "aws_iam_user_policy" "requester_pays" {
  name = "requester-pays-${var.environment}-policy"
  user = aws_iam_user.requester_pays.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "arn:aws:s3:::lcl-cogs/*",
          "arn:aws:s3:::gfw-data-lake/*"
        ]
        Condition = {
          StringEquals = {
            "s3:x-amz-request-payer" = "requester"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::lcl-cogs",
          "arn:aws:s3:::gfw-data-lake"
        ]
        Condition = {
          StringEquals = {
            "s3:x-amz-request-payer" = "requester"
          }
        }
      }
    ]
  })
}

# Access key for the IAM user
resource "aws_iam_access_key" "requester_pays" {
  user = aws_iam_user.requester_pays.name
}

# Kubernetes secret for requester pays S3 credentials
resource "kubernetes_secret" "requester_pays_s3_credentials" {
  metadata {
    name      = "requester-pays-s3-credentials"
    namespace = "eoapi"
  }

  data = {
    AWS_ACCESS_KEY_ID     = aws_iam_access_key.requester_pays.id
    AWS_SECRET_ACCESS_KEY = aws_iam_access_key.requester_pays.secret
  }
}