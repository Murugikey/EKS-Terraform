output "cluster_id" {
  description = "The id of the EKS cluster. Will block on cluster creation until the cluster is really ready."
  value       = aws_eks_cluster.cluster.id
}

output "cluster_name" {
  description = "The name of the EKS cluster."
  value       = aws_eks_cluster.cluster.name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = aws_eks_cluster.cluster.endpoint
}

output "bastionhost_rolearn" {
  description = "Role ARN of BastionHost"
  value       = aws_iam_role.eks_bastion_host_role.arn
}

output "workernode_rolearn" {
  description = "Role ARN of WorkerNodes"
  value       = aws_iam_role.eks_bastion_host_role.arn
}

output "node_group_names" {
  description = "Node Group name created"
  value       = aws_eks_node_group.eks_node_groups[*].resources[0].autoscaling_groups[0].name
}

output "eks_cluster_worker_node_sg" {
  description = "EKS Security Group ID"
  value       = aws_security_group.eks_cluster_worker_node_sg.id
}