# ALB Module - main.tf

resource "aws_lb" "this" {
  name               = var.name
  load_balancer_type = "application"
  
  subnets         = var.subnets
  security_groups = var.security_groups
  
  internal                   = var.internal
  enable_deletion_protection = var.enable_deletion_protection
  
  enable_http2                     = var.enable_http2
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  enable_waf_fail_open            = var.enable_waf_fail_open
  
  drop_invalid_header_fields = var.drop_invalid_header_fields
  preserve_host_header       = var.preserve_host_header
  
  idle_timeout                = var.idle_timeout
  desync_mitigation_mode     = var.desync_mitigation_mode
  
  dynamic "access_logs" {
    for_each = var.access_logs != null ? [var.access_logs] : []
    content {
      bucket  = access_logs.value.bucket
      prefix  = lookup(access_logs.value, "prefix", null)
      enabled = lookup(access_logs.value, "enabled", true)
    }
  }

  tags = var.tags
}

# Target Groups
resource "aws_lb_target_group" "this" {
  count = length(var.target_groups)

  name     = var.target_groups[count.index].name
  port     = var.target_groups[count.index].port
  protocol = var.target_groups[count.index].protocol
  vpc_id   = var.vpc_id
  
  target_type                       = lookup(var.target_groups[count.index], "target_type", "instance")
  deregistration_delay             = lookup(var.target_groups[count.index], "deregistration_delay", 300)
  slow_start                       = lookup(var.target_groups[count.index], "slow_start", 0)
  load_balancing_algorithm_type    = lookup(var.target_groups[count.index], "load_balancing_algorithm_type", "round_robin")
  preserve_client_ip              = lookup(var.target_groups[count.index], "preserve_client_ip", null)
  protocol_version                = lookup(var.target_groups[count.index], "protocol_version", null)

  dynamic "health_check" {
    for_each = length(keys(lookup(var.target_groups[count.index], "health_check", {}))) == 0 ? [] : [lookup(var.target_groups[count.index], "health_check", {})]
    content {
      enabled             = lookup(health_check.value, "enabled", null)
      healthy_threshold   = lookup(health_check.value, "healthy_threshold", null)
      interval            = lookup(health_check.value, "interval", null)
      matcher             = lookup(health_check.value, "matcher", null)
      path                = lookup(health_check.value, "path", null)
      port                = lookup(health_check.value, "port", null)
      protocol            = lookup(health_check.value, "protocol", null)
      timeout             = lookup(health_check.value, "timeout", null)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", null)
    }
  }

  dynamic "stickiness" {
    for_each = length(keys(lookup(var.target_groups[count.index], "stickiness", {}))) == 0 ? [] : [lookup(var.target_groups[count.index], "stickiness", {})]
    content {
      enabled         = lookup(stickiness.value, "enabled", null)
      cookie_duration = lookup(stickiness.value, "cookie_duration", null)
      cookie_name     = lookup(stickiness.value, "cookie_name", null)
      type            = stickiness.value.type
    }
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Target Group Attachments
resource "aws_lb_target_group_attachment" "this" {
  count = length(flatten([
    for tg_index, tg in var.target_groups : [
      for target in lookup(tg, "targets", []) : {
        tg_index = tg_index
        target   = target
      }
    ]
  ]))

  target_group_arn = aws_lb_target_group.this[
    flatten([
      for tg_index, tg in var.target_groups : [
        for target in lookup(tg, "targets", []) : {
          tg_index = tg_index
          target   = target
        }
      ]
    ])[count.index].tg_index
  ].arn

  target_id = flatten([
    for tg_index, tg in var.target_groups : [
      for target in lookup(tg, "targets", []) : {
        tg_index = tg_index
        target   = target
      }
    ]
  ])[count.index].target

  port = var.target_groups[
    flatten([
      for tg_index, tg in var.target_groups : [
        for target in lookup(tg, "targets", []) : {
          tg_index = tg_index
          target   = target
        }
      ]
    ])[count.index].tg_index
  ].port
}

# Listeners
resource "aws_lb_listener" "this" {
  count = length(var.listeners)

  load_balancer_arn = aws_lb.this.arn
  port              = var.listeners[count.index].port
  protocol          = var.listeners[count.index].protocol
  ssl_policy        = lookup(var.listeners[count.index], "ssl_policy", null)
  certificate_arn   = lookup(var.listeners[count.index], "certificate_arn", null)
  alpn_policy       = lookup(var.listeners[count.index], "alpn_policy", null)

  default_action {
    type             = var.listeners[count.index].action_type
    target_group_arn = var.listeners[count.index].action_type == "forward" ? aws_lb_target_group.this[lookup(var.listeners[count.index], "target_group_index", 0)].arn : null

    dynamic "redirect" {
      for_each = var.listeners[count.index].action_type == "redirect" ? [lookup(var.listeners[count.index], "redirect", {})] : []
      content {
        port        = lookup(redirect.value, "port", "#{port}")
        protocol    = lookup(redirect.value, "protocol", "#{protocol}")
        status_code = lookup(redirect.value, "status_code", "HTTP_301")
        host        = lookup(redirect.value, "host", "#{host}")
        path        = lookup(redirect.value, "path", "/#{path}")
        query       = lookup(redirect.value, "query", "#{query}")
      }
    }

    dynamic "fixed_response" {
      for_each = var.listeners[count.index].action_type == "fixed-response" ? [lookup(var.listeners[count.index], "fixed_response", {})] : []
      content {
        content_type = fixed_response.value.content_type
        message_body = lookup(fixed_response.value, "message_body", null)
        status_code  = lookup(fixed_response.value, "status_code", "200")
      }
    }
  }

  tags = var.tags
}
