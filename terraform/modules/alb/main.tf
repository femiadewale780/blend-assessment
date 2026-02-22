resource "aws_lb" "this" {
  name               = "alb-${var.name}"
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids
  tags               = merge(var.tags, { Name = "alb-${var.name}" })
  enable_https      = true
  certificate_arn   = var.alb_certificate_arn
  enable_http_redirect = true
  dynamic "access_logs" {
  for_each = var.enable_access_logs && var.access_logs_bucket != null ? [1] : []
  content {
    enabled = true
    bucket  = var.access_logs_bucket
    prefix  = coalesce(var.access_logs_prefix, "alb/${var.name}")
  }
}

}

resource "aws_lb_target_group" "this" {
  name        = "tg-${var.name}"
  port        = var.target_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200-399"
  }

  tags = merge(var.tags, { Name = "tg-${var.name}" })
}


# HTTP listener (80): either forward (old behavior) OR redirect to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.enable_http_redirect && var.enable_https ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = var.enable_http_redirect && var.enable_https ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    dynamic "forward" {
      for_each = !(var.enable_http_redirect && var.enable_https) ? [1] : []
      content {
        target_group_arn = aws_lb_target_group.this.arn
      }
    }
  }
}

# HTTPS listener (443): forwards to target group
resource "aws_lb_listener" "https" {
  count             = var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

