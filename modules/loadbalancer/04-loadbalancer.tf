resource "aws_lb" "loadbalancer" {
  name                       = var.IDENTIFIER
  load_balancer_type         = var.TYPE
  internal                   = var.ACCESS_TYPE == "private" ? true : false
  subnets                    = var.SUBNETS.private
  security_groups            = var.TYPE != "network" ? [aws_security_group.default_lb_sg[0].id] : []
  enable_deletion_protection = var.DELETION_PROTECTION
  drop_invalid_header_fields = false

  access_logs {
    bucket  = aws_s3_bucket.load_balancers_s3_bucket.bucket
    prefix  = "${upper(var.TYPE)}-LOAD-BALANCER"
    enabled = true
  }

  depends_on = [
    aws_s3_bucket.load_balancers_s3_bucket
  ]

  tags = merge(
    var.DEFAULT_TAGS,
    {
      "Name"         = "${var.NAME_PREFIX}-${var.TYPE}-lb-${var.IDENTIFIER}"
      "Purpose"      = "Load Balancer ${upper(var.TYPE)}  - ${upper(var.DEFAULT_TAGS.Project)}"
      "SecurityZone" = "X2"
    },
  )
}

resource "aws_lb_target_group" "target_groups" {
  count      = length(var.TARGETS)
  name       = "${var.IDENTIFIER}-${var.TARGETS[count.index].name}"
  
  port       = var.TARGETS[count.index].port
  protocol   = var.TARGETS[count.index].protocol
  vpc_id     = var.VPC_ID

  health_check {
    port                = var.TARGETS[count.index].healthcheck.port
    protocol            = var.TARGETS[count.index].protocol
    # healthy_threshold   = each.value.healthy_threshold
    # unhealthy_threshold = each.value.unhealthy_threshold
    # timeout             = each.value.timeout
    # interval            = each.value.interval
    matcher             = var.TARGETS[count.index].healthcheck.matcher
    path                = var.TARGETS[count.index].healthcheck.path
  }

  tags = merge(
    var.DEFAULT_TAGS,
    tomap({
      "Name" = "${var.NAME_PREFIX}-${var.TYPE}-lb-${var.IDENTIFIER}-${var.TARGETS[count.index].name}"
      "Purpose" = "Load Balancer ${upper(var.TYPE)} Target Group - ${upper(var.DEFAULT_TAGS.Project)}"
      "SecurityZone" = "E-I"
    })
  )

  depends_on = [
    aws_lb.loadbalancer
  ]
}

resource "aws_lb_listener" "listeners" {
  count             = length(var.LISTENERS)
  load_balancer_arn = aws_lb.loadbalancer.arn
  port              = var.LISTENERS[count.index].port_forward
  protocol          = var.LISTENERS[count.index].protocol
  
  ssl_policy        = (var.LISTENERS[count.index].protocol == "HTTPS") ? "ELBSecurityPolicy-FS-1-2-Res-2020-10" : null
  certificate_arn   = (var.LISTENERS[count.index].protocol == "HTTPS") ? var.LISTENERS[count.index].certificate_arn : null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_groups[var.LISTENERS[count.index].target_index].arn
  }

  depends_on = [
    aws_lb_target_group.target_groups
  ]
}

# Create an ALB Target Group attachment

## Instance attachements
resource "aws_lb_target_group_attachment" "instances" {
  count            = length(var.instances) 
  target_group_arn = aws_lb_target_group.target_groups[var.instances[count.index].target_index].arn
  target_id        = var.instances[count.index].id
  port             = var.instances[count.index].port
}