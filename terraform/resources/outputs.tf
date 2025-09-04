output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value = var.aws_region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value = module.eks.cluster_name
}

output "requester_pays_access_key_id" {
  description = "Access Key ID for requester pays S3 access"
  value = aws_iam_access_key.requester_pays.id
}

output "requester_pays_secret_key" {
  description = "Secret Access Key for requester pays S3 access"
  value = aws_iam_access_key.requester_pays.secret
  sensitive = true
}

output "node_groups_asg_names" {
  description = "List of the autoscaling group names for EKS managed node groups"
  value = module.eks.eks_managed_node_groups_autoscaling_group_names
}
