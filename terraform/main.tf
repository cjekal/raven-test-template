# Create an ALB that points to the NodePort of the service

resource "aws_acm_certificate" "springboot-server-certificate" {
  domain_name       = var.url
  validation_method = "DNS"
}

resource "aws_route53_record" "springboot-server-certificate-dns-validation" {
  for_each = {
    for dvo in aws_acm_certificate.springboot-server-certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}

resource "aws_acm_certificate_validation" "springboot-server-certificate-validation" {
  certificate_arn         = aws_acm_certificate.springboot-server-certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.springboot-server-certificate-dns-validation : record.fqdn]
}

resource "aws_security_group" "springboot-server-alb-security-group" {
  name   = "springboot-server-alb-sg"
  vpc_id = var.vpc_id
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "springboot-server-alb" {
  name               = "springboot-server-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.subnets
  security_groups    = [aws_security_group.springboot-server-alb-security-group.id]
}

resource "aws_lb_target_group" "springboot-server-target-group" {
  name     = "springboot-server-target-group"
  port     = var.nodeport
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path = "/actuator/"
  }
}

resource "aws_lb_target_group_attachment" "springboot-server-target-group-attachment" {
  for_each         = toset(var.instance_ids)
  target_group_arn = aws_lb_target_group.springboot-server-target-group.arn
  target_id        = each.value
}

resource "aws_lb_listener" "springboot-server-listener" {
  load_balancer_arn = aws_lb.springboot-server-alb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.springboot-server-certificate-validation.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.springboot-server-target-group.arn
  }
}

resource "aws_lb_listener" "springboot-server-listener-http" {
  load_balancer_arn = aws_lb.springboot-server-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_route53_record" "springboot-server-route53-record" {
  zone_id = var.zone_id
  name    = var.url
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.springboot-server-alb.dns_name]
}
