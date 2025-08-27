# OIDC Identity Provider (should already exist, but adding for completeness)
data "tls_certificate" "eks_cluster" {
  url = module.eks.cluster_oidc_issuer_url
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  count           = length(data.aws_iam_openid_connect_provider.eks_oidc.arn) > 0 ? 0 : 1
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_cluster.certificates[0].sha1_fingerprint]
  url             = module.eks.cluster_oidc_issuer_url
}

data "aws_iam_openid_connect_provider" "eks_oidc" {
  url = module.eks.cluster_oidc_issuer_url
}

# IAM Role for Cluster Autoscaler
data "aws_iam_policy_document" "cluster_autoscaler_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      identifiers = [data.aws_iam_openid_connect_provider.eks_oidc.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "cluster_autoscaler" {
  name               = "${local.cluster_name}-cluster-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.cluster_autoscaler_assume_role_policy.json
}

# Scoped IAM Policy for Cluster Autoscaler
data "aws_iam_policy_document" "cluster_autoscaler_policy" {
  statement {
    sid    = "ClusterAutoscalerAll"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DescribeInstanceTypes"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ClusterAutoscalerOwn"
    effect = "Allow"
    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup"
    ]
    resources = [
      for asg_name in module.eks.eks_managed_node_groups_autoscaling_group_names :
      "arn:aws:autoscaling:${var.aws_region}:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/${asg_name}"
    ]
  }
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "${local.cluster_name}-cluster-autoscaler"
  path        = "/"
  description = "IAM policy for cluster autoscaler on ${local.cluster_name}"
  policy      = data.aws_iam_policy_document.cluster_autoscaler_policy.json
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}

# Output the IAM role ARN for use with Helm
output "cluster_autoscaler_iam_role_arn" {
  description = "ARN of the IAM role for cluster autoscaler"
  value       = aws_iam_role.cluster_autoscaler.arn
}