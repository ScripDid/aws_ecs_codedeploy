data "aws_route53_zone" "registered_public_domain" {
  name         = "${var.dns_domain_name}"
  private_zone = false
}

resource "aws_route53_record" "service_route53_record" {
  zone_id = "${data.aws_route53_zone.registered_public_domain.zone_id}"
  name    = "${var.dns_hostname}"
  type    = "${var.dns_rr_type}"
  ttl     = "${var.dns_rr_ttl}"
  records = ["${aws_alb.ecs_cluster_alb.dns_name}"]
}

resource "aws_route53_record" "cert_validation_route53_record" {
  count   = "${var.alb_protocol == "HTTPS" ? 1 : 0 }"
  name    = "${aws_acm_certificate.alb_certificate.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.alb_certificate.domain_validation_options.0.resource_record_type}"
  zone_id = "${var.r53_zone_id != "" ? var.r53_zone_id : data.aws_route53_zone.registered_public_domain.zone_id}"
  records = ["${aws_acm_certificate.alb_certificate.domain_validation_options.0.resource_record_value}"]
  ttl     = "${var.dns_ttl}"
}
