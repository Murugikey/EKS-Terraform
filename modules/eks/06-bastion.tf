resource "aws_instance" "eks_bastion_host" {
  count                  = contains(keys(var.INSTANCE_DEFINITIONS), "eks_bastion_host") ? 1 : 0
  ami                    = var.INSTANCE_DEFINITIONS.eks_bastion_host.ami
  instance_type          = var.INSTANCE_DEFINITIONS.eks_bastion_host.instance_type
  iam_instance_profile   = aws_iam_instance_profile.bastion_host_instance_profile.id
  subnet_id              = var.PVT_SUBNETS[0] 
  vpc_security_group_ids = [aws_security_group.eks_cluster_bastion_host_sg.id]
  root_block_device {
    volume_size = var.INSTANCE_DEFINITIONS.eks_bastion_host.root_volume_size
    encrypted   = true
    //missing kms key id 
    tags = merge(
      var.DEFAULT_TAGS,
      {
         "Purpose"      = "Root volume for ${var.NAME_PREFIX} EKS bastion host}"
         "Name"         = "${var.NAME_PREFIX}-eks-bastion-root-volume"
         "SecurityZone" = "C2"
      }
    )
         #lifecycle {
    #  ignore_changes = [
    #    tags
    #  ]
    #}
  }

  tags = merge(
    var.DEFAULT_TAGS,
    { 
      "Name"         = "${var.NAME_PREFIX}-eks-internal-bastion-host"
      "Purpose"      = "BastionHost to access EKS Cluster - ${upper(var.DEFAULT_TAGS.Project)}",
      "VendorRole"   = var.VENDOR_ROLE
      "trend-plan"   = var.TREND_PLAN
      "AutoTurnOFF"  = var.AUTO_TURN_OFF
      "StartTime"    = var.APP_START_TIME
      "StopTime"     = var.APP_STOP_TIME
      "${var.NAME_PREFIX}.Backup"       = "true"
    }
  )

  user_data = base64encode(
    templatefile("${path.module}/bh-userdata.tpl",
      {
        CLUSTER_NAME     = aws_eks_cluster.cluster.name,
        PROJECT          = var.DEFAULT_TAGS.Project 
        REGION           = data.aws_region.current.name
      }
    )
  )

  lifecycle {
    ignore_changes = [
      volume_tags
    ]
  }

  depends_on = [
    aws_eks_cluster.cluster, 
    aws_eks_node_group.eks_node_groups
  ]
}