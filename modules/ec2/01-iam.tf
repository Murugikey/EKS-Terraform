resource "aws_iam_instance_profile" "ec2_instance_profile" {
  count = var.CREATE_INSTANCE_PROFILE ? 1 : 0
  name  = "${var.NAME_PREFIX}-${var.TAG_NAME}-instance-profile"
  role  = aws_iam_role.ec2_instance_role[count.index].name
}

resource "aws_iam_role" "ec2_instance_role" {
  count              = var.CREATE_INSTANCE_PROFILE ? 1 : 0
  name               = "${var.NAME_PREFIX}-${var.TAG_NAME}-role"
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

#resource "aws_iam_policy" "ec2_log_policy" {
#  name        = "${var.NAME_PREFIX}-${var.TAG_NAME}-log-role-policy"
#  path        = "/"
#  description = "Allows an instance to forward logs to CloudWatch, s3 and SSM"
#
#  policy = <<EOF
#{
#  "Version": "2012-10-17",
#  "Statement": [
#      {}
#    ]
#}
#EOF
#}

resource "aws_iam_role_policy_attachment" "aws_policy_attachment_default" {
  count      = length(aws_iam_role.ec2_instance_role[0].name) > 0 ? length(var.AWS_IAM_POLICIES) : 0
  role       = aws_iam_role.ec2_instance_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/${var.AWS_IAM_POLICIES[count.index]}"

}

resource "aws_iam_role_policy_attachment" "custom_ec2_iam_policy_attachment_default" {
  count      = length(aws_iam_role.ec2_instance_role[0].name) > 0 ? length(var.CUSTOM_IAM_POLICIES) : 0
  role       = aws_iam_role.ec2_instance_role[0].name
  policy_arn = var.CUSTOM_IAM_POLICIES[count.index].arn

}

resource "aws_iam_role_policy_attachment" "aws_policy_attachment_custom" {
  count      = length(var.EC2_INSTANCE_ROLE) > 0 ? length(var.AWS_IAM_POLICIES) : 0
  role       = var.EC2_INSTANCE_ROLE.name
  policy_arn = "arn:aws:iam::aws:policy/${var.AWS_IAM_POLICIES[count.index]}"

}

resource "aws_iam_role_policy_attachment" "custom_ec2_iam_policy_attachment_custom" {
  count      = length(var.EC2_INSTANCE_ROLE) > 0 ? length(var.CUSTOM_IAM_POLICIES) : 0
  role       = var.EC2_INSTANCE_ROLE.name
  policy_arn = var.CUSTOM_IAM_POLICIES[count.index].arn

}

