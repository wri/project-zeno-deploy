# Simple version using the EKS IAM module
module "cluster_autoscaler_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${local.cluster_name}-cluster-autoscaler"

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [local.cluster_name]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }
}

# Output for Helm
output "cluster_autoscaler_iam_role_arn" {
  description = "ARN of the IAM role for cluster autoscaler"
  value       = module.cluster_autoscaler_irsa.iam_role_arn
}