##################################
####### EC2 Instance Setup #######
##################################

resource "aws_instance" "ec2_instance" {
  count                       = var.TYPE == "EC2" ? length(var.SUBNET_LIST) : 0
  ami                         = var.INSTANCE_DEFINITIONS.ami
  instance_type               = var.INSTANCE_DEFINITIONS.instance_type
  iam_instance_profile        = length(var.INSTANCE_PROFILE) > 0 ? var.INSTANCE_PROFILE : aws_iam_instance_profile.ec2_instance_profile[0].name
  subnet_id                   = var.SUBNET_LIST[count.index]
  monitoring                  = true
  associate_public_ip_address = var.ASSOCIATE_PUBLIC_IP

  vpc_security_group_ids = [
      aws_security_group.security_group.id
  ]
  
  root_block_device {
    volume_size = var.INSTANCE_DEFINITIONS.root_volume_size
    encrypted   = true
    #kms_key_id  = aws_kms_key.self_managed_ec2_kms_volumes_key.arn
    
    tags = merge(
      var.DEFAULT_TAGS, 
      {
        "Purpose"      = "Root volume for ${var.NAME_PREFIX}.${var.TAG_NAME}"
        "Name"         = "${var.NAME_PREFIX}-${var.TAG_NAME}-root-volume-${length(var.SUBNET_LIST)-count.index}"
        "SecurityZone" = "C2"
      }
    )
  }
  
  #volume_tags = merge(
  #  var.DEFAULT_TAGS,
  #  {
  #    "Purpose"      = "Root volume for ${var.NAME_PREFIX}.${count.index + 1}"
  #    "Name"         = "${var.NAME_PREFIX}-root-volume.${count.index + 1}"
  #    "SecurityZone" = "c2"
  #  }
  #)
  
  user_data = length(var.CUSTOM_USERDATA_FILENAME) > 0 ? base64encode( # Merging of default user data with the EFS user data 
    join("\n",
      [ 
        templatefile("${path.module}/utils/${var.EC2_USERDATA_FILENAME}", # EC2 User Data file
          { 
            PROJECT          = var.DEFAULT_TAGS.Project 
            REGION           = data.aws_region.current.name
          }
        ),
        templatefile("${path.module}/utils/${var.CUSTOM_USERDATA_FILENAME}", # EFS User Data file
          {
            EFS_DNS          = var.EFS_DNS
            EFS_MOUNT_PATH   = var.EFS_MOUNT_PATH
          }
        )
      ]
    )
  ) : base64encode( # No merge if the EFS_DNS is not defined
    templatefile("${path.module}/utils/${var.EC2_USERDATA_FILENAME}", 
      { 
        PROJECT          = var.DEFAULT_TAGS.Project 
        REGION           = data.aws_region.current.name
      }
    )
  )

  tags = merge(
    var.DEFAULT_TAGS,
    {
      "Name"         = "${var.NAME_PREFIX}-${var.TAG_NAME}-${length(var.SUBNET_LIST)-count.index}"
      "Purpose"      = "Instance for ${var.TAG_NAME}-${var.DEFAULT_TAGS.Project}",
      "SecurityZone" = "X2"
      "VendorRole"   = var.VENDOR_ROLE
      "trend-plan"   = var.TREND_PLAN
      "AutoTurnOFF"  = var.AUTO_TURN_OFF
      "StartTime"    = var.APP_START_TIME
      "StopTime"     = var.APP_STOP_TIME
      "${var.NAME_PREFIX}.Backup"       = "true"
    }
  ) 
  lifecycle {
    ignore_changes = [
      user_data#,
      # volume_tags, 
      # root_block_device
    ]
  }
}

resource "aws_eip" "ec2_eip" {
  count    = var.CREATE_EIP == true ? length(var.SUBNET_LIST) : 0
  instance = aws_instance.ec2_instance[count.index].id
  vpc      = true

  tags = merge(
    var.DEFAULT_TAGS, 
    {
      "Purpose"      = "EIP for ${var.TYPE} Access ${upper(var.DEFAULT_TAGS.Project)} - ${upper(var.TAG_NAME)}"
      "Name"         = "${var.NAME_PREFIX}-${var.TYPE}-${var.TAG_NAME}-eip.${count.index + 1}"
      "SecurityZone" = "E-I"
    },
  )
}

resource "aws_eip_association" "eip_assoc" {
  count         = var.CREATE_EIP == true ? length(var.SUBNET_LIST) : 0
  instance_id   = aws_instance.ec2_instance[count.index].id
  allocation_id = aws_eip.ec2_eip[count.index].id
}

resource "aws_autoscaling_group" "asg" {
  count               = var.TYPE == "ASG" ? 1 : 0
  #availability_zones  = [element(data.aws_availability_zones.available.names, 0), element(data.aws_availability_zones.available.names, 0)]
  #availability_zones  = data.aws_availability_zones.available.names # in the event of wanting to span all availability zones
  name                = replace("${var.NAME_PREFIX}-${var.TAG_NAME}-${var.TYPE}", ".", "-")
  vpc_zone_identifier = var.SUBNET_LIST
  
  desired_capacity    = var.ASG_DESIRED
  max_size            = var.ASG_MAX
  min_size            = var.ASG_MIN

  force_delete        = var.ASG_FORCE_DELETE
  health_check_type   = var.ASG_HEALTH_CHECK

  launch_template {
    id      = aws_launch_template.asg_launch_template[count.index].id
    version = aws_launch_template.asg_launch_template[count.index].latest_version
  }

  lifecycle {
    ignore_changes = [
      load_balancers,
      target_group_arns
    ]
  }
}

resource "aws_launch_template" "asg_launch_template" {
  count                  = var.TYPE == "ASG" ? 1 : 0
  name                   = "${var.NAME_PREFIX}-${var.TAG_NAME}-${var.TYPE}-LT"
  image_id               = var.INSTANCE_DEFINITIONS.ami
  instance_type          = var.INSTANCE_DEFINITIONS.instance_type 
  update_default_version = var.UPDATE_ASG
  vpc_security_group_ids = [aws_security_group.security_group.id]

  user_data = length(var.EFS_DNS) > 0 ? base64encode( # Merging of default user data with the EFS user data 
    join("\n",
      [ 
        templatefile("${path.module}/utils/${var.ASG_USERDATA_FILENAME}", # EC2 User Data file
          { 
            PROJECT          = var.DEFAULT_TAGS.Project 
            REGION           = data.aws_region.current.name
          }
        ),
        templatefile("${path.module}/utils/${var.CUSTOM_USERDATA_FILENAME}", # EFS User Data file
          {
            EFS_DNS          = var.EFS_DNS
            EFS_MOUNT_PATH   = var.EFS_MOUNT_PATH
          }
        )
      ]
    )
  ) : base64encode( # No merge if the EFS_DNS is not defined
    templatefile("${path.module}/utils/${var.ASG_USERDATA_FILENAME}", 
      { 
        PROJECT          = var.DEFAULT_TAGS.Project 
        REGION           = data.aws_region.current.name
      }
    )
  )

  iam_instance_profile {
    name = length(var.INSTANCE_PROFILE) > 0 ? var.INSTANCE_PROFILE : aws_iam_instance_profile.ec2_instance_profile[0].name
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = var.INSTANCE_DEFINITIONS.root_volume_size
    }
  }

  tag_specifications {
    resource_type = "instance"
    
    tags = merge(
      var.DEFAULT_TAGS,
      {
        Name       = "${var.NAME_PREFIX}-${var.TAG_NAME}-${var.TYPE}-node"
        LifeCycle  = var.ASG_LIFECYCLE
      }
    )
  }
}