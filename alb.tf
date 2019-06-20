resource "aws_alb" "ecs_cluster_alb" {
  name               = "alb-${var.owner}-${var.application}"
  internal           = "${var.bool_alb_internal}"
  load_balancer_type = "${var.load_balancer_type}"

  access_logs {
    bucket  = "${data.terraform_remote_state.foundation.log_delivery_bucket}"
    prefix  = "alb-${var.owner}-${var.application}"
    enabled = true
  }

  subnets = ["${data.terraform_remote_state.foundation.public_subnets_list}"]

  security_groups            = ["${aws_security_group.alb_security_group.id}"]
  enable_deletion_protection = false

  tags = "${merge(
    map(
      "Description", "Application Load Balancer deployed by ${var.operator}"
    ),
    "${local.mandatory_tags}"
  )}"
}
