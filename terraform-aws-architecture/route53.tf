resource "aws_route53_zone" "main" {
  count = var.create_route53_zone ? 1 : 0
  name  = var.domain_name

  tags = {
    Name = "${var.project_name}-zone"
  }
}

locals {
  zone_id = var.create_route53_zone ? aws_route53_zone.main[0].zone_id : var.route53_zone_id
}

resource "aws_route53_record" "main" {
  zone_id = local.zone_id
  name    = "${var.subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}
