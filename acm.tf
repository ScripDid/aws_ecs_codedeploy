resource "aws_acm_certificate" "alb_certificate" {
  count             = "${var.alb_protocol == "HTTPS" ? 1 : 0 }"
  domain_name       = "${var.dns_hostname}.${var.dns_domain_name != "" ? var.dns_domain_name : var.dns_domain_name}"
  validation_method = "${var.acm_cert_validation_method}"

  tags = "${merge(
    map(
      "Description", "ALB certificate for app ${var.application}"
    ),
    "${local.mandatory_tags}"
  )}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "alb_acm_certificate_validation" {
  # depends_on              = ["aws_route53_record.cert_validation_route53_record"]
  count                   = "${var.alb_protocol == "HTTPS" ? 1 : 0 }"
  certificate_arn         = "${aws_acm_certificate.alb_certificate.0.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation_route53_record.fqdn}"]
}

# resource "aws_route53_record" "cert_validation" {
#   name    = "${aws_acm_certificate.alb_certificate.domain_validation_options.0.resource_record_name}"
#   type    = "${aws_acm_certificate.alb_certificate.domain_validation_options.0.resource_record_type}"
#   zone_id = "${data.terraform_remote_state.foundation.public_r53_zone_id}"
#   records = ["${aws_acm_certificate.alb_certificate.domain_validation_options.0.resource_record_value}"]
#   ttl     = 60
# }

