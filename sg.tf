# Security groups for instances

resource "aws_security_group" "ecs_instance_security_group" {
  name_prefix = "SG_ECS_INSTANCES"
  description = "Security group for ${var.application} ECS container instances"
  vpc_id      = "${data.terraform_remote_state.foundation.main_vpc_id}"
  tags        = "${local.mandatory_tags}"
}

resource "aws_security_group_rule" "ecs_instance_outbound_sg_rule" {
  type              = "egress"
  description       = "Outbound access for ${var.application}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ecs_instance_security_group.id}"
}

# Security groups for ALB

resource "aws_security_group" "alb_security_group" {
  name        = "SG_ECS_CLUSTER_ALB"
  vpc_id      = "${data.terraform_remote_state.foundation.main_vpc_id}"
  description = "Security group of ECS cluster ALB"
  tags        = "${local.mandatory_tags}"
}

# resource "aws_security_group_rule" "alb_inbound_security_group_rule" {
#   description       = "Alb inbound access for ${var.application}"
#   type              = "ingress"
#   from_port         = "${var.alb_port_range_FROM}"
#   to_port           = "${var.alb_port_range_TO}"
#   protocol          = "TCP"
#   cidr_blocks       = "${var.alb_ingress_cidr_block}"
#   security_group_id = "${aws_security_group.alb_security_group.id}"
# }

resource "aws_security_group_rule" "alb_egress_security_group_rule" {
  description       = "Outbound access for ${var.application}"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.alb_security_group.id}"
}


resource "aws_security_group_rule" "alb_to_ecs_sec_grp_rule" {
  description              = "Access between Alb and ECS Instance"
  type                     = "ingress"
  from_port                = "${var.ecs_sg_port_range_from}"
  to_port                  = "${var.ecs_sg_port_range_to}"
  protocol                 = "TCP"
  source_security_group_id = "${element(concat(aws_security_group.alb_security_group.*.id, list("")), 0)}"
  security_group_id        = "${aws_security_group.ecs_instance_security_group.id}"
}


# resource "aws_security_group_rule" "additional_alb_inbound_security_group_rule" {
#   count                    = "${length(var.alb_additional_security_group_ids)}"
#   description              = "Alb additional inbound access for ${var.application}"
#   type                     = "ingress"
#   from_port                = "${var.alb_port_range_FROM}"
#   to_port                  = "${var.alb_port_range_TO}"
#   protocol                 = "TCP"
#   source_security_group_id = "${var.alb_additional_security_group_ids[count.index]}"
#   security_group_id        = "${aws_security_group.alb_security_group.id}"
# }

