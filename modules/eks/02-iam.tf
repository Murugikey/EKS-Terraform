### ROLES
# EKS Control Plane
resource "aws_iam_role" "eks_control_plane_role" {
  name = "${var.NAME_PREFIX}-eks-control-plane-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "eks.amazonaws.com", 
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
# Kubectl Role
resource "aws_iam_role" "kubectl_eks_role" {
  name = "${var.DEFAULT_TAGS.Project}-kubectl-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",    
          "arn:aws:iam::556361159589:role/${var.DEFAULT_TAGS.Project}-sandbox-cicd-codebuild-role-yxvu"
        ] 
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
# WorkerNodes Role for LaunchTemplate
resource "aws_iam_role" "eks_workernode_role" {
  name = "${var.NAME_PREFIX}-eks-node-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
        
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
# BastionHost Role of Instance
resource "aws_iam_role" "eks_bastion_host_role" {
  name = "${var.NAME_PREFIX}-eks-bastion-host-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# # ALB Ingress Role
### Remove ALB Ingress for now
### PathRule problem
### https://github.com/kubernetes-sigs/aws-load-balancer-controller/issues/835
### https://github.com/kubernetes-sigs/aws-load-balancer-controller/issues/699

#resource "aws_iam_role" "eks_alb_ingress_role" {
#  name = "${var.NAME_PREFIX}-eks-alb-ingress-role"
#  assume_role_policy = <<POLICY
#{
#    "Version": "2012-10-17",
#    "Statement": [
#        {
#            "Effect": "Allow",
#            "Principal": {
#              "Federated": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${trimprefix(aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://")}"
#            },
#            "Action": "sts:AssumeRoleWithWebIdentity",
#            "Condition": {
#                "StringEquals": {
#                    "${trimprefix(aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://")}:aud": "sts.amazonaws.com",
#                    "${trimprefix(aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://")}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
#                }
#            }
#        }
#    ]
#}
#  POLICY
#  depends_on = [
#    aws_eks_identity_provider_config.eks_cluster
#  ]
#}



### Policies
#
resource "aws_iam_policy" "eks-cluster-kubectl-policy" {
  name        = "${var.NAME_PREFIX}-eks-assume-policy"
  path        = "/"
  description = "Minimum permissions to view EKS worker nodes"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": "eks.amazonaws.com"
                                 }
                         }
        }
    ]
}
  EOF
}

###AmazonEKS_Viewnodes_Policy
resource "aws_iam_policy" "eks-cluster-viewnodes-policy" {
  name        = "${var.NAME_PREFIX}-eks-viewnodes-policy"
  path        = "/"
  description = "Minimum permissions to view EKS worker nodes"

  policy = <<EOF
{
  "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:DescribeNodegroup",
                "eks:ListNodegroups",
                "eks:DescribeCluster",
                "eks:ListClusters",
                "eks:AccessKubernetesApi",
                "ssm:GetParameter",
                "eks:ListUpdates"
            ],
            "Resource": "*"
        }
     ]   
   }
  EOF
}
## Access logs
resource "aws_iam_policy" "workernode_log_policy" {
  name        = "${var.NAME_PREFIX}-workernode-role-policy"
  path        = "/"
  description = "Allows an instance to forward logs to CloudWatch, s3 and SSM"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:PutLogEvents",
              "logs:PutRetentionPolicy",
              "logs:DescribeLogStreams"
            ],
            "Resource": [
                "arn:aws:logs:*:*:*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:PutObjectAcl",
                "s3:GetEncryptionConfiguration"
            ],
            "Resource": [
                "arn:aws:s3:::${local.logging_bucket_name}",
                "arn:aws:s3:::${replace(var.NAME_PREFIX, "/[^-a-zA-Z0-9]/", "-")}-start-up-scripts",
                "arn:aws:s3:::${replace(var.NAME_PREFIX, "/[^-a-zA-Z0-9]/", "-")}-start-up-scripts/*",
                "arn:aws:s3:::${replace(var.NAME_PREFIX, "/[^-a-zA-Z0-9]/", "-")}-artifacts",
                "arn:aws:s3:::${replace(var.NAME_PREFIX, "/[^-a-zA-Z0-9]/", "-")}-artifacts/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeAssociation",
                "ssm:GetDeployablePatchSnapshotForInstance",
                "ssm:GetDocument",
                "ssm:GetManifest",
                "ssm:GetParameters",
                "ssm:ListAssociations",
                "ssm:ListInstanceAssociations",
                "ssm:PutInventory",
                "ssm:PutComplianceItems",
                "ssm:PutConfigurePackageResult",
                "ssm:UpdateAssociationStatus",
                "ssm:UpdateInstanceAssociationStatus",
                "ssm:UpdateInstanceInformation"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2messages:AcknowledgeMessage",
                "ec2messages:DeleteMessage",
                "ec2messages:FailMessage",
                "ec2messages:GetEndpoint",
                "ec2messages:GetMessages",
                "ec2messages:SendReply"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstanceStatus"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ds:CreateComputer",
                "ds:DescribeDirectories"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
             {
            "Effect": "Allow",
            "Action": [
                "eks:DescribeNodegroup",
                "eks:ListNodegroups",
                "eks:DescribeCluster",
                "eks:ListClusters",
                "eks:AccessKubernetesApi",
                "ssm:GetParameter",
                "eks:ListUpdates"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetEncryptionConfiguration",
                "s3:AbortMultipartUpload",
                "s3:ListMultipartUploadParts",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads"
            ],
            "Resource": [
                "arn:aws:s3:::aws-ssm-${data.aws_region.current.name}/*",
                "arn:aws:s3:::aws-windows-downloads-${data.aws_region.current.name}/*",
                "arn:aws:s3:::amazon-ssm-${data.aws_region.current.name}/*",
                "arn:aws:s3:::amazon-ssm-packages-${data.aws_region.current.name}/*",
                "arn:aws:s3:::${data.aws_region.current.name}-birdwatcher-prod/*",
                "arn:aws:s3:::patch-baseline-snapshot-${data.aws_region.current.name}/*"
            ]
        }
    ]
}
EOF
}

### ALB Ingress Policy

### Remove ALB Ingress for now
### PathRule problem
### https://github.com/kubernetes-sigs/aws-load-balancer-controller/issues/835
### https://github.com/kubernetes-sigs/aws-load-balancer-controller/issues/699

resource "aws_iam_policy" "eks_alb_ingress_policy" {
  name        = "${var.NAME_PREFIX}-eks-alb-ingress-policy"
  path        = "/"
  description = "Allows Kubernetes manage resources around ALB Ingress"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceLinkedRole"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:AWSServiceName": "elasticloadbalancing.amazonaws.com"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeAccountAttributes",
                "ec2:DescribeAddresses",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeInternetGateways",
                "ec2:DescribeVpcs",
                "ec2:DescribeVpcPeeringConnections",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeInstances",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeTags",
                "ec2:GetCoipPoolUsage",
                "ec2:DescribeCoipPools",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeLoadBalancerAttributes",
                "elasticloadbalancing:DescribeListeners",
                "elasticloadbalancing:DescribeListenerCertificates",
                "elasticloadbalancing:DescribeSSLPolicies",
                "elasticloadbalancing:DescribeRules",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeTargetGroupAttributes",
                "elasticloadbalancing:DescribeTargetHealth",
                "elasticloadbalancing:DescribeTags"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cognito-idp:DescribeUserPoolClient",
                "acm:ListCertificates",
                "acm:DescribeCertificate",
                "iam:ListServerCertificates",
                "iam:GetServerCertificate",
                "waf-regional:GetWebACL",
                "waf-regional:GetWebACLForResource",
                "waf-regional:AssociateWebACL",
                "waf-regional:DisassociateWebACL",
                "wafv2:GetWebACL",
                "wafv2:GetWebACLForResource",
                "wafv2:AssociateWebACL",
                "wafv2:DisassociateWebACL",
                "shield:GetSubscriptionState",
                "shield:DescribeProtection",
                "shield:CreateProtection",
                "shield:DeleteProtection"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupIngress"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSecurityGroup"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags"
            ],
            "Resource": "arn:aws:ec2:*:*:security-group/*",
            "Condition": {
                "StringEquals": {
                    "ec2:CreateAction": "CreateSecurityGroup"
                },
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags",
                "ec2:DeleteTags"
            ],
            "Resource": "arn:aws:ec2:*:*:security-group/*",
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:DeleteSecurityGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:CreateTargetGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:CreateListener",
                "elasticloadbalancing:DeleteListener",
                "elasticloadbalancing:CreateRule",
                "elasticloadbalancing:DeleteRule"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:RemoveTags"
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
            ],
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:RemoveTags"
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
                "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
                "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
                "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:ModifyLoadBalancerAttributes",
                "elasticloadbalancing:SetIpAddressType",
                "elasticloadbalancing:SetSecurityGroups",
                "elasticloadbalancing:SetSubnets",
                "elasticloadbalancing:DeleteLoadBalancer",
                "elasticloadbalancing:ModifyTargetGroup",
                "elasticloadbalancing:ModifyTargetGroupAttributes",
                "elasticloadbalancing:DeleteTargetGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:DeregisterTargets"
            ],
            "Resource": "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:SetWebAcl",
                "elasticloadbalancing:ModifyListener",
                "elasticloadbalancing:AddListenerCertificates",
                "elasticloadbalancing:RemoveListenerCertificates",
                "elasticloadbalancing:ModifyRule"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

### Attachaments

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_control_plane_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_control_plane_role.name
}
resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_control_plane_role.name
}
resource "aws_iam_role_policy_attachment" "KubernetesViewOnlyRole" {
  role       = aws_iam_role.eks_control_plane_role.name
  policy_arn = aws_iam_policy.eks-cluster-viewnodes-policy.arn

  depends_on = [
    aws_iam_policy.eks-cluster-viewnodes-policy
  ]
}
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_workernode_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_workernode_role.name
}
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_workernode_role.name
}
resource "aws_iam_role_policy_attachment" "wn_CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.eks_workernode_role.name
}
#resource "aws_iam_role_policy_attachment" "ALBIngressRolePolicy" {
#  role       = aws_iam_role.eks_alb_ingress_role.name
#  policy_arn = aws_iam_policy.eks_alb_ingress_policy.arn
#}
resource "aws_iam_role_policy_attachment" "KubernetesViewOnlyRole_node" {
  role       = aws_iam_role.eks_workernode_role.name
  policy_arn = aws_iam_policy.eks-cluster-viewnodes-policy.arn

  depends_on = [
    aws_iam_policy.eks-cluster-viewnodes-policy
  ]
}
resource "aws_iam_role_policy_attachment" "workernode_policy_attachment" {
  role       = aws_iam_role.eks_workernode_role.name
  policy_arn = aws_iam_policy.workernode_log_policy.arn
}
resource "aws_iam_role_policy_attachment" "kubectl_policy_attachment" {
  role       = aws_iam_role.kubectl_eks_role.name
  policy_arn = aws_iam_policy.eks-cluster-kubectl-policy.arn
}

resource "aws_iam_instance_profile" "bastion_host_instance_profile" {
  name = "${var.NAME_PREFIX}-bastion-host-profile"
  role = aws_iam_role.eks_bastion_host_role.name
}

resource "aws_iam_role_policy_attachment" "bastionhost_ssm_policy_attachment" {
  role       = aws_iam_role.eks_bastion_host_role.name
  policy_arn = aws_iam_policy.workernode_log_policy.arn
}

#Its needed yet ? 
resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  role = aws_iam_role.eks_bastion_host_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"  
}

resource "aws_iam_role_policy_attachment" "CloudWatchAgentServerPolicy" {
  role       = aws_iam_role.eks_bastion_host_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "AWSCloudFormationReadOnlyAccess" {
  role       = aws_iam_role.eks_bastion_host_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudFormationReadOnlyAccess"
} 

# Allow CodeCommit repositories
# resource "aws_iam_role_policy_attachment" "codebuild_allow_codecommit" {
#   ## Cross-Account ROLE ?? ${var.NAME_PREFIX}-codecommit-allow-pull-push
#   role       = "arn:aws:iam::556361159589:role/${var.DEFAULT_TAGS.Project}-codebuild-role"
#   policy_arn = "arn:aws:iam::aws:policy/AWSCloudFormationReadOnlyAccess"
# }


####
# Monitor IAM Needs

resource "aws_iam_policy" "monitor_policy" {
  count       = var.MONITOR_CONFIG.install ? 1 : 0
  name        = "${var.NAME_PREFIX}-monitor-metrics-logs-policy"
  path        = "/"
  description = "Permissions to Grafana read logs and metrics from CloudWatch"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowReadingMetricsFromCloudWatch",
      "Effect": "Allow",
      "Action": [
        "cloudwatch:DescribeAlarmsForMetric",
        "cloudwatch:DescribeAlarmHistory",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:ListMetrics",
        "cloudwatch:GetMetricData",
        "cloudwatch:GetInsightRuleReport"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowReadingLogsFromCloudWatch",
      "Effect": "Allow",
      "Action": [
        "logs:DescribeLogGroups",
        "logs:GetLogGroupFields",
        "logs:StartQuery",
        "logs:StopQuery",
        "logs:GetQueryResults",
        "logs:GetLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowReadingTagsInstancesRegionsFromEC2",
      "Effect": "Allow",
      "Action": ["ec2:DescribeTags", "ec2:DescribeInstances", "ec2:DescribeRegions"],
      "Resource": "*"
    },
    {
      "Sid": "AllowReadingResourcesForTags",
      "Effect": "Allow",
      "Action": "tag:GetResources",
      "Resource": "*"
    },
    {
      "Sid": "AllowDeleteLogs",
      "Effect": "Allow",
      "Action": ["logs:DeleteLogStream", "logs:DeleteLogGroup"],
      "Resource": "*"
    }
  ]
}
  EOF   
}

resource "aws_iam_role_policy_attachment" "monitor_attach_policy" {
  count      = var.MONITOR_CONFIG.install ? 1 : 0
  role       = aws_iam_role.eks_workernode_role.name
  policy_arn = aws_iam_policy.monitor_policy[0].arn
}

resource "aws_iam_policy" "csi_driver_policy" {
  name        = "${var.NAME_PREFIX}-csi_driver_policy"
  path        = "/"
  description = "Permissions to access EFS for EKS"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticfilesystem:DescribeAccessPoints",
        "elasticfilesystem:DescribeFileSystems",
        "elasticfilesystem:DescribeMountTargets",
        "ec2:DescribeAvailabilityZones"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [ "elasticfilesystem:CreateAccessPoint"],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/efs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": ["elasticfilesystem:DeleteAccessPoint"],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/efs.csi.aws.com/cluster": "true"
        }
      }
    }
  ]
}
  EOF  
}

resource "aws_iam_role" "csi_driver" {
  name = "${var.NAME_PREFIX}-csi_driver_role"
  path = "/"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${trimprefix(aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://")}"
      }
      Condition = {
        StringEquals = {
          "${trimprefix(aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://")}:sub" : "system:serviceaccount:efs-provisioner:efs-provisioner",
          "${trimprefix(aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://")}:aud": "sts.amazonaws.com",
        }
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "csi_driver_policy_attachment" {
  role       = aws_iam_role.csi_driver.name
  policy_arn = aws_iam_policy.csi_driver_policy.arn

  depends_on = [
    aws_iam_role.csi_driver
  ]

}