# ---------------------------------------------------------
# 1. ZONA DNS (Route 53)
# ---------------------------------------------------------
resource "aws_route53_zone" "main" {
  name = var.root_domain_name

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ---------------------------------------------------------
# 2. CERTIFICADO ACM (Validación Automática)
# ---------------------------------------------------------
resource "aws_acm_certificate" "gateway_cert" {
  domain_name       = "${var.api_subdomain}.${var.root_domain_name}"
  validation_method = "DNS"

  tags = {
    Name = "${var.project}-${var.environment}-gateway-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Crea el registro CNAME automáticamente en la zona de arriba para validar que eres el dueño
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.gateway_cert.domain_validation_options : dvo.domain_name => {
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
  zone_id         = aws_route53_zone.main.zone_id
}

# Espera a que AWS confirme la validación
resource "aws_acm_certificate_validation" "gateway_cert_valid" {
  certificate_arn         = aws_acm_certificate.gateway_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# ---------------------------------------------------------
# 3. LOAD BALANCER & TARGET GROUP
# ---------------------------------------------------------
resource "aws_lb_target_group" "gateway" {
  name        = "tg-gateway-apisix"
  port        = 9080  # Puerto del contenedor APISIX
  protocol    = "TCP" # NLB -> APISIX (TCP puro)
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  target_type = "ip" # OBLIGATORIO para Fargate

  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 10
  }
}

resource "aws_lb" "gateway_nlb" {
  name               = "nlb-gateway"
  load_balancer_type = "network"
  internal           = false # PÚBLICO
  subnets            = data.terraform_remote_state.vpc.outputs.public_subnet_ids

  enable_cross_zone_load_balancing = true

  tags = {
    Component = "nlb"
  }
}

resource "aws_lb_listener" "gateway_tls_443" {
  load_balancer_arn = aws_lb.gateway_nlb.arn
  port              = 443
  protocol          = "TLS"
  certificate_arn   = aws_acm_certificate_validation.gateway_cert_valid.certificate_arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gateway.arn
  }
}

# ---------------------------------------------------------
# 4. REGISTRO DNS FINAL (El Alias)
# ---------------------------------------------------------
# Esto crea "api.ztest.click" apuntando al NLB
resource "aws_route53_record" "gateway_alias" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "${var.api_subdomain}.${var.root_domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.gateway_nlb.dns_name
    zone_id                = aws_lb.gateway_nlb.zone_id
    evaluate_target_health = true
  }
}
