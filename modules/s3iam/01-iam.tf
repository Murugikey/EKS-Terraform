resource "aws_iam_role" "commom_instance_role" {
  name = "${var.name_prefix}-commom-instance-role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow"
        }
    ]
}
EOF
}
resource "aws_iam_instance_profile" "commom_instance_profile" {
  name = "${var.name_prefix}-commom-instance-profile"
  role = aws_iam_role.commom_instance_role.name
}

resource "aws_iam_role_policy_attachment" "iam_policy" {
  role       = aws_iam_role.commom_instance_role.name
  policy_arn = aws_iam_policy.common_log_instances_policy.arn
}


##IAM Policy
resource "aws_iam_policy" "common_log_instances_policy" {
  name        = "${var.name_prefix}-common-log-instances-policy"
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
                "arn:aws:s3:::${replace(var.name_prefix, "/[^-a-zA-Z0-9]/", "-")}-start-up-scripts",
                "arn:aws:s3:::${replace(var.name_prefix, "/[^-a-zA-Z0-9]/", "-")}-start-up-scripts/*",
                "arn:aws:s3:::${replace(var.name_prefix, "/[^-a-zA-Z0-9]/", "-")}-artifacts",
                "arn:aws:s3:::${replace(var.name_prefix, "/[^-a-zA-Z0-9]/", "-")}-artifacts/*"
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