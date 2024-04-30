data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_eks_cluster_auth" "cluster" {
  name = "${replace(var.NAME_PREFIX, "/[^-a-zA-Z0-9]/", "-")}-eks-cluster-${var.CLUSTER_ORDER_NUMBER}"
}