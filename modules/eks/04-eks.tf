provider "kubernetes" {
  host                   = aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

resource "aws_eks_cluster" "cluster" {            
  name                      = "${replace(var.NAME_PREFIX, "/[^-a-zA-Z0-9]/", "-")}-eks-cluster-${var.CLUSTER_ORDER_NUMBER}"
  version                   = var.K8S_VERSION
  role_arn                  = aws_iam_role.eks_control_plane_role.arn
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  vpc_config {
    subnet_ids              = setunion(var.PUB_SUBNETS, var.PVT_SUBNETS) //? Maybe just publics subnets here?
    security_group_ids      = [aws_security_group.eks_cluster_control_plane_sg.id]

    # endpoint_private_access = false # Indicates whether or not the Amazon EKS private API server endpoint is enabled
    # endpoint_public_access  = true  # Indicates whether or not the Amazon EKS public API server endpoint is enabled
  }

  depends_on = [
    aws_iam_role.eks_control_plane_role,
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
  ]

  tags = merge(
    var.DEFAULT_TAGS,
    {
      "Name"         = "${var.NAME_PREFIX}-eks-cluster-${var.CLUSTER_ORDER_NUMBER}"
      "Purpose"      = "EKS Cluster Source - ${upper(var.DEFAULT_TAGS.Project)}"
      "SecurityZone" = "X2"
    },
  )
}

resource "aws_eks_node_group" "eks_node_groups" {
  count           = length(var.NG_CAPACITY_TYPE)
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = var.NG_CAPACITY_TYPE[count.index] == "SPOT" ? "${replace(var.NAME_PREFIX, "/[^-a-zA-Z0-9]/", "-")}-eks-spot-NG" : "${replace(var.NAME_PREFIX, "/[^-a-zA-Z0-9]/", "-")}-eks-on-demand-NG"
  node_role_arn   = aws_iam_role.eks_workernode_role.arn
  subnet_ids      = var.PVT_SUBNETS
  capacity_type   = var.NG_CAPACITY_TYPE[count.index]

  #ami_type       = var.NG_CAPACITY_TYPE[count.index] == "SPOT" ? var.INSTANCE_DEFINITIONS.spot_worker_nodes.ami_type : var.INSTANCE_DEFINITIONS.on_demand_worker_nodes.ami_type
  instance_types = var.NG_CAPACITY_TYPE[count.index] == "SPOT" ? [var.INSTANCE_DEFINITIONS.spot_worker_nodes.instance_type, "m4.xlarge", "c5.2xlarge", "r5.large", "t3.xlarge"] : [var.INSTANCE_DEFINITIONS.on_demand_worker_nodes.instance_type]
  #disk_size      = var.NG_CAPACITY_TYPE[count.index] == "SPOT" ? 20 : 50
  
  scaling_config {
    desired_size = var.NG_CAPACITY_TYPE[count.index] == "SPOT" ? var.SPOT_DESIRED_SIZE : var.ON_DEMAND_DESIRED_SIZE
    max_size     = var.NG_CAPACITY_TYPE[count.index] == "SPOT" ? var.SPOT_MAX_SIZE : var.ON_DEMAND_MAX_SIZE
    min_size     = var.NG_CAPACITY_TYPE[count.index] == "SPOT" ? var.SPOT_MIN_SIZE : var.ON_DEMAND_MIN_SIZE
  }

  launch_template {
    id      = aws_launch_template.node_launch_template[count.index].id
    #id      = aws_launch_template.spot_node_launch_template.id
    version = aws_launch_template.node_launch_template[count.index].latest_version
    #version = aws_launch_template.spot_node_launch_template.latest_version
  }

  depends_on = [
    aws_eks_cluster.cluster,
    aws_iam_role.eks_workernode_role,
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    kubernetes_config_map.aws_auth
  ]

  tags = merge(
    var.DEFAULT_TAGS,
    {
    "Name"         = var.NG_CAPACITY_TYPE[count.index] == "SPOT" ? "${var.NAME_PREFIX}-eks-spot-worker-node-private.${var.NG_ORDER_NUMBER}" : "${var.NAME_PREFIX}-eks-on-demand-node-private.${var.NG_ORDER_NUMBER}"
    "Purpose"      = var.NG_CAPACITY_TYPE[count.index] == "SPOT" ? "EKS ${aws_eks_cluster.cluster.name} Spot Node Group - - ${upper(var.DEFAULT_TAGS.Project)}" : "EKS ${aws_eks_cluster.cluster.name} On Demand Node Group - - ${upper(var.DEFAULT_TAGS.Project)}" 
    "SecurityZone" = "X2"
    }
  )
}

resource "aws_launch_template" "node_launch_template" {
  count                  = length(var.NG_CAPACITY_TYPE)
  name_prefix            = var.NG_CAPACITY_TYPE[count.index] == "SPOT" ? "${aws_eks_cluster.cluster.name}-spot-nodes-launch-template" : "${aws_eks_cluster.cluster.name}-on-demand-launch-template"
  image_id               = var.INSTANCE_DEFINITIONS.spot_worker_nodes.ami
  #instance_type          = var.INSTANCE_DEFINITIONS.spot_worker_nodes.instance_type
  update_default_version = true
  vpc_security_group_ids = [aws_security_group.eks_cluster_worker_node_sg.id]
  
  user_data = base64encode(
    templatefile("${path.module}/wn-userdata.tpl", 
      { 
        CLUSTER_NAME    = aws_eks_cluster.cluster.name
        B64_CLUSTER_CA  = aws_eks_cluster.cluster.certificate_authority[0].data
        API_SERVER_URL  = aws_eks_cluster.cluster.endpoint
        NODE_GROUP_NAME = "${replace(var.NAME_PREFIX, "/[^-a-zA-Z0-9]/", "-")}-eks-node-private-${var.NG_ORDER_NUMBER}"
        CAPACITY        = var.NG_CAPACITY_TYPE[count.index] == "SPOT" ? "SPOT" : "ON_DEMAND"
        EC2_AMI         = var.INSTANCE_DEFINITIONS.spot_worker_nodes.ami
      }
    )
  )

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 20
    }
  }

  tag_specifications {
    resource_type = "instance" 
    
    tags = merge(
      var.DEFAULT_TAGS,
      {
        Name       = var.NG_CAPACITY_TYPE[count.index] == "SPOT" ? "${var.NAME_PREFIX}-spot-worker-node" : "${var.NAME_PREFIX}-on-demand-worker-node"
        LifeCycle  = var.NG_CAPACITY_TYPE[count.index] == "SPOT" ? "SPOT" : "ON_DEMAND"
        "VendorRole"   = "DevOps4"
      }
    )
  }
}

# Iam service account for EFS Provisioner
resource "kubernetes_service_account" "efs-provisioner" {
    metadata {
        name = "efs-provisioner"
        annotations = {
            "eks.amazonaws.com/role-arn" = "${aws_iam_role.csi_driver.arn}"
        }
        namespace = "efs-provisioner"
    }

    depends_on = [
      aws_eks_cluster.cluster
    ]

}

# Auth in EKS Cluster
resource "kubernetes_config_map" "aws_auth" {
  data = {
    "mapRoles" = <<YAML
- rolearn: ${aws_iam_role.eks_workernode_role.arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
- rolearn: ${aws_iam_role.eks_bastion_host_role.arn}
  username: admin
  groups:
    - system:masters
- rolearn: 'arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/SysAdmin'
  username: sysadmin
  groups:
   - system:masters
- rolearn: 'arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/DevOps4'
  username: devops4
  groups:
   - developer
YAML
  }
  metadata { 
    name      = "aws-auth"
    namespace = "kube-system"
  }

  depends_on = [
    aws_eks_cluster.cluster
  ]
}

### Remove ALB Ingress for now 
### PathRule problem
### https://github.com/kubernetes-sigs/aws-load-balancer-controller/issues/835
### https://github.com/kubernetes-sigs/aws-load-balancer-controller/issues/699

resource "aws_iam_openid_connect_provider" "eks_cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [local.eks_oidc_thumbprint["${data.aws_region.current.name}"]]
  url             = "${aws_eks_cluster.cluster.identity[0].oidc[0].issuer}"
  
  tags = merge(
    var.DEFAULT_TAGS,
    {
    "Name"         = "${var.NAME_PREFIX}-eks-cluster-${var.CLUSTER_ORDER_NUMBER}-iam-openid-provider"
    "Purpose"      = "IAM OpenID Provider ${var.NAME_PREFIX} of ALB Ingress and others connectors"
    "SecurityZone" = "X2"
    }
  )
}

resource "aws_eks_identity_provider_config" "eks_cluster" {
  cluster_name = aws_eks_cluster.cluster.name
  oidc {
    client_id                     = "sts.amazonaws.com"
    identity_provider_config_name = "${replace(var.NAME_PREFIX, "/[^-a-zA-Z0-9]/", "-")}-eks-cluster-${var.CLUSTER_ORDER_NUMBER}-oicd-provider"
    issuer_url                    = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  }
  
  tags = merge(
    var.DEFAULT_TAGS,
    {
    "Name"         = "${var.NAME_PREFIX}-eks-cluster-${var.CLUSTER_ORDER_NUMBER}-oicd-provider"
    "Purpose"      = "EKS ${var.NAME_PREFIX} ALB Ingress and others connectors"
    "SecurityZone" = "X2"
    }
  )
}