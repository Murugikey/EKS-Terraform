#####
### EKS Cluster Control Plane SG
resource "aws_security_group" "eks_cluster_control_plane_sg" {
  name        = "${var.NAME_PREFIX}-eks-cluster.control-plane-sg"
  description = "Control Plane Security group for EKS Cluster"
  vpc_id      = var.VPC_ID

  tags = merge(
    var.DEFAULT_TAGS,
    {
      "Name"         = "${var.NAME_PREFIX}-cluster.control-plane-sg"
      "Purpose"      = "Control Plane Security group for EKS Cluster - ${upper(var.DEFAULT_TAGS.Project)}"
      "SecurityZone" = "X2"
    },
  )
}

#####
### EKS Cluster WorkerNode SG
resource "aws_security_group" "eks_cluster_worker_node_sg" {
  name        = "${var.NAME_PREFIX}-workernode.worker-node-sg"
  description = "Worker Nodes Security group for EKS Cluster"
  vpc_id      = var.VPC_ID

  tags = merge(
    var.DEFAULT_TAGS,
    {
      "Name"         = "${var.NAME_PREFIX}-workernode.worker-node-sg"
      "Purpose"      = "Worker Nodes Security group for EKS Cluster - ${upper(var.DEFAULT_TAGS.Project)}"
      "SecurityZone" = "X2"
    },
  )
}

####
## EKS Cluster BastionHost SG
resource "aws_security_group" "eks_cluster_bastion_host_sg" {
  name        = "${var.NAME_PREFIX}-bastion-host-sg"
  description = "Bastion Host Security group for EKS Cluster"
  vpc_id      = var.VPC_ID

  tags = merge(
    var.DEFAULT_TAGS,
    {
      "Name"         = "${var.NAME_PREFIX}-bastion-host-sg"
      "Purpose"      = "Bastion Host Security group for EKS Cluster - ${upper(var.DEFAULT_TAGS.Project)}"
      "SecurityZone" = "X2"
    },
  )

  lifecycle {
    ignore_changes = [
      # tags, 
      # tags_all, 
      name
    ]
  }
}

#####
### Load Balancer SG
resource "aws_security_group" "eks_lb_default_sg" {
  name        = "${var.NAME_PREFIX}-eks-lb-default-sg"
  description = "Default SG for LB to EKS - ${upper(var.DEFAULT_TAGS.Project)}"
  vpc_id      = var.VPC_ID

  tags = merge(
    var.DEFAULT_TAGS,
    {
      "Name"         = "${var.NAME_PREFIX}-eks-lb-default-sg"
      "Purpose"      = "Default SG for LB to EKS - ${upper(var.DEFAULT_TAGS.Project)}"
      "SecurityZone" = "X2"
    },
  )
}

########
## Inbound/Outbound Rules

resource "aws_security_group_rule" "ssm_https_out_int" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.eks_cluster_worker_node_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Security Group Rule to allow egress connections for ssm"
}

resource "aws_security_group_rule" "ssm_http_out_int" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.eks_cluster_worker_node_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Security Group Rule to allow egress connections for ssm"
}

# resource "aws_security_group_rule" "cluster_service_access" {
#   description              = "Allow NTGW communicate with the cluster API Services"
#   from_port                = 30000
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.eks_cluster_control_plane_sg.id
#   cidr_blocks              = ["52.212.192.55/32"]
#   to_port                  = 32767
#   type                     = "ingress"
# }

resource "aws_security_group_rule" "cluster_outbound" {
  count                    = length(var.PVT_SUBNET_CIDRS)
  description              = "Allow cluster API Server to communicate with the worker nodes"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_cluster_control_plane_sg.id
  cidr_blocks              = [var.PVT_SUBNET_CIDRS[count.index]]
  to_port                  = 0
  type                     = "egress"
}

resource "aws_security_group_rule" "cluster_inbound" {
  count                    = length(var.PVT_SUBNET_CIDRS)
  description              = "Allow he worker nodes to communicate with cluster API Server"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_cluster_control_plane_sg.id
  cidr_blocks              = [var.PVT_SUBNET_CIDRS[count.index]]
  to_port                  = 0
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks_lb_ingress_access" {
  type              = "ingress"
  from_port         = 30080
  to_port           = 30080
  protocol          = "tcp"
  security_group_id = aws_security_group.eks_cluster_worker_node_sg.id
  cidr_blocks       = [var.VPC_CIDR]
  #source_security_group_id  = aws_security_group.eks_lb_default_sg.id
  description       = "Allow http traffic from elb to nodes"
}

#resource "aws_security_group_rule" "load_balancer_egress" {
#  type              = "egress"
#  from_port         = 0
#  to_port           = 65535
#  protocol          = "tcp"
#  security_group_id = aws_security_group.eks_lb_default_sg.id
#  cidr_blocks       = [var.VPC_CIDR]
#  description       = "Allow http traffic in vpc cidr"
#}

resource "aws_security_group_rule" "eks_argo_lb_access" {
  type              = "ingress"
  from_port         = 30081
  to_port           = 30081
  protocol          = "tcp"
  security_group_id = aws_security_group.eks_cluster_worker_node_sg.id
  cidr_blocks       = [var.VPC_CIDR]
  description       = "Allow http traffic from elb to nodes"
}

resource "aws_security_group_rule" "eks_grafana_lb_access" {
  type              = "ingress"
  from_port         = 30082
  to_port           = 30082
  protocol          = "tcp"
  security_group_id = aws_security_group.eks_cluster_worker_node_sg.id
  cidr_blocks       = [var.VPC_CIDR]
  description       = "Allow http traffic from elb to nodes"
}

#resource "aws_security_group_rule" "eks_lb_ingress_access_http" {
#  type              = "ingress"
#  from_port         = 80
#  to_port           = 80
#  protocol          = "tcp"
#  security_group_id = aws_security_group.eks_cluster_worker_node_sg.id
#  source_security_group_id  = aws_security_group.eks_lb_default_sg.id
#  description       = "Allow http traffic from elb to nodes"
#}

resource "aws_security_group_rule" "workernode_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.eks_cluster_worker_node_sg.id
  cidr_blocks       = [var.VPC_CIDR]
  description       = "Allow ssh traffic in vpc cidr"
}

resource "aws_security_group_rule" "workernode_dnsudp" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  security_group_id = aws_security_group.eks_cluster_worker_node_sg.id
  cidr_blocks       = [var.VPC_CIDR]
  description       = "Allow DNS UDP traffic"
}

resource "aws_security_group_rule" "workernode_outbound" {
  description              = "Allow cluster API Server to communicate with the worker nodes"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_cluster_worker_node_sg.id
  cidr_blocks              = ["0.0.0.0/0"]
  to_port                  = 0
  type                     = "egress"
}
resource "aws_security_group_rule" "workernode_smtp_outbound465" {
  description              = "Allow cluster Nodes communicates with SMTP (465) server"
  from_port                = 465
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_worker_node_sg.id
  cidr_blocks              = ["0.0.0.0/0"]
  to_port                  = 465
  type                     = "egress"
}

resource "aws_security_group_rule" "workernode_smtp_outbound587" {
  description              = "Allow cluster Nodes communicates with SMTP (587) server"
  from_port                = 587
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_worker_node_sg.id
  cidr_blocks              = ["0.0.0.0/0"]
  to_port                  = 587
  type                     = "egress"
}

resource "aws_security_group_rule" "workernode_prometheus_out_traffic" {
  description              = "Allow cluster Nodes send out prometheus metrics"
  from_port                = 9100
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_worker_node_sg.id
  cidr_blocks              = ["0.0.0.0/0"]
  to_port                  = 9100
  type                     = "egress"
}

resource "aws_security_group_rule" "bastionhost_outbound_https" {
  type                     = "egress"
  description              = "Allow outgoing all HTTPS traffic (TCP/443) from BastionHosts"
  protocol                 = "TCP"
  security_group_id        = aws_security_group.eks_cluster_bastion_host_sg.id
  cidr_blocks              = ["0.0.0.0/0"]
  from_port                = 443
  to_port                  = 443
}

resource "aws_security_group_rule" "bastionhost_outbound_sshkeyscan" {
  type                     = "egress"
  description              = "Allow outgoing all SSH traffic (TCP/22) for SSH KEYSCAN CodeCommit proposes"
  protocol                 = "TCP"
  security_group_id        = aws_security_group.eks_cluster_bastion_host_sg.id
  cidr_blocks              = ["0.0.0.0/0"]
  from_port                = 22
  to_port                  = 22
}

resource "aws_security_group_rule" "bastionhost_inbound_ssh" {
  type                     = "ingress"
  description              = "Allow income VPC CIDR subnet - temporary -  for kubectl jumpbox access"
  protocol                 = "TCP"
  security_group_id        = aws_security_group.eks_cluster_bastion_host_sg.id
  cidr_blocks              = ["${var.VPC_CIDR}"]
  from_port                = 22
  to_port                  = 22
}

resource "aws_security_group_rule" "bastion_eks_access" {
  description              = "Allow cluster Nodes access from bastion"
  from_port                = 0
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_worker_node_sg.id
  cidr_blocks              = [var.VPC_CIDR]
  to_port                  = 65535
  type                     = "ingress"
}


resource "aws_security_group_rule" "chat_ejabberd_c2s_rule" {
  description              = "Allow cluster Nodes access to HA Proxy for Chat EjabberD C2S"
  from_port                = 5222
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_worker_node_sg.id
  cidr_blocks              = [var.VPC_CIDR]
  to_port                  = 5222
  type                     = "egress"
}

resource "aws_security_group_rule" "chat_ejabberd_https_rule" {
  description              = "Allow cluster Nodes access to HA Proxy for Chat EjabberD HTTPS"
  from_port                = 5443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_worker_node_sg.id
  cidr_blocks              = [var.VPC_CIDR]
  to_port                  = 5443
  type                     = "egress"
}

resource "aws_security_group_rule" "chat_ejabberd_service_rule" {
  description              = "Allow cluster Nodes access to HA Proxy for Chat EjabberD Service"
  from_port                = 5347
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_worker_node_sg.id
  cidr_blocks              = [var.VPC_CIDR]
  to_port                  = 5347
  type                     = "egress"
}

resource "aws_security_group_rule" "chat_ejabberd_http_rule" {
  description              = "Allow cluster Nodes access to HA Proxy for Chat EjabberD HTTP"
  from_port                = 4443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_worker_node_sg.id
  cidr_blocks              = [var.VPC_CIDR]
  to_port                  = 4443
  type                     = "egress"
}

resource "aws_security_group_rule" "chat_cantaloupe_service_rule" {
  description              = "Allow cluster Nodes access to HA Proxy for Chat Cantaloupe Service"
  from_port                = 8183
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_worker_node_sg.id
  cidr_blocks              = [var.VPC_CIDR]
  to_port                  = 8183
  type                     = "egress"
}

resource "aws_security_group_rule" "chat_cantaloupe_upload_rule" {
  description              = "Allow cluster Nodes access to HA Proxy for Chat Cantaloupe Upload"
  from_port                = 2222
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_worker_node_sg.id
  cidr_blocks              = [var.VPC_CIDR]
  to_port                  = 2222
  type                     = "egress"
}