
data "aws_route53_zone" "hashidemos" {
  name         = var.route53_zone_name
  private_zone = false
}

resource "aws_route53_record" "prometheus" {
  zone_id = data.aws_route53_zone.hashidemos.zone_id
  name    = "prometheus"
  type    = "CNAME"
  ttl     = 300
  records = [data.kubernetes_service.prometheus.status.0.load_balancer.0.ingress.0.hostname]
}