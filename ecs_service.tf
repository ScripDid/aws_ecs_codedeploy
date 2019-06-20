#====> Create the Target Group

resource "aws_alb_target_group" "service_alb_target_group" {
  name                 = "tg-${var.owner}-${var.application}-${var.container_port}"
  port                 = "${var.container_port}"
  protocol             = "${var.container_protocol}"
  vpc_id               = "${data.terraform_remote_state.foundation.main_vpc_id}"
  deregistration_delay = "${var.deregistration_delay}"

  health_check {
    path                = "${var.health_check_path}"
    protocol            = "${var.health_check_protocol}"
    port                = "${var.host_port != 0 ? var.host_port : "traffic-port"}"
    matcher             = "${var.health_check_matcher}"
    healthy_threshold   = "${var.health_check_threshold}"
    unhealthy_threshold = "${var.health_check_uthreashold}"
    timeout             = "${var.health_check_timeout}"
    interval            = "${var.health_check_interval}"
  }

  stickiness {
    type = "${var.tg_sticky_type}"
  }

  tags = "${local.common_tags}"

  lifecycle {
    create_before_destroy = true
  }
}

#====> Create the ALB Listener for the Target Group

resource "aws_alb_listener" "service_alb_listener" {
  load_balancer_arn = "${aws_alb.ecs_cluster_alb.arn}"
  port              = "${var.service_port}"
  protocol          = "${var.alb_protocol}"
  ssl_policy        = "${var.alb_protocol == "HTTPS" ? var.listener_ssl_policy : "" }"
  certificate_arn   = "${var.alb_protocol == "HTTPS" ? element(concat(aws_acm_certificate_validation.cert_validation_acm_certificate_validation.*.certificate_arn, list("")), 0) : "" }"

  default_action {
    target_group_arn = "${aws_alb_target_group.service_alb_target_group.id}"
    type             = "${var.listener_default_action_type}"
  }
}

#====> Create and register a Task Definition

data "template_file" "task_definition_template_file" {
  template = "${file("${path.module}/templates/task-definition-template.json")}"

  vars {
    TASK_NAME                   = "td-${var.owner}-${var.application}-${var.service_name}"
    IMAGE_TAG                   = "${var.image}:${var.image_tag}"
    CONTAINER_PORT              = "${var.container_port}"
    HOST_PORT                   = "${var.host_port}"
    CLOUDWATCH_LOG_GROUP_DOCKER = "${var.cloudwatch_log_group_docker}"
    CLOUDWATCH_STREAM_PREFIX    = "cls-${var.owner}-${var.application}-${var.service_name}"
    REGION                      = "${var.region}"
    CONTAINER_CPU               = "${var.container_cpu}"
    CONTAINER_MEMORY            = "${var.container_memory_reservation}"
  }
}

resource "aws_ecs_task_definition" "service_ecs_task_definition" {
  family                = "td-${var.owner}-${var.application}-${var.service_name}"
  container_definitions = "${var.task_definition != "" ?
                          var.task_definition : data.template_file.task_definition_template_file.rendered}"

  volume = "${concat(var.volume_definition_1,
                     var.volume_definition_2,
                     var.volume_definition_3,
                     var.volume_definition_4,
                     var.volume_definition_5,
                     var.volume_definition_6,
                     var.volume_definition_7,
                     var.volume_definition_8,
                     var.volume_definition_9,
                     var.volume_definition_10)}"

  task_role_arn = "${var.task_role_arn}"
  depends_on    = ["aws_alb_listener.service_alb_listener"]
}

#====> Create the Service

resource "aws_ecs_service" "service_ecs_service" {
  name                               = "${var.service_name}"
  cluster                            = "${aws_ecs_cluster.ecs_cluster.id}"
  task_definition                    = "${aws_ecs_task_definition.service_ecs_task_definition.arn}"
  desired_count                      = "${var.desired_count}"
  iam_role                           = "${var.service_role_arn}"
  deployment_minimum_healthy_percent = "${var.min_health_percent}"
  deployment_maximum_percent         = "${var.max_health_percent}"
  scheduling_strategy                = "${var.scheduling_strategy}"

  load_balancer {
    target_group_arn = "${aws_alb_target_group.service_alb_target_group.arn}"
    container_name   = "td-${var.owner}-${var.application}-${var.service_name}"
    container_port   = "${var.container_port}"
  }

  ordered_placement_strategy = "${var.ordered_placement_strategy}"

  lifecycle {
    ignore_changes = ["desired_count"]
  }
}

#====> Create Record to Route53 private Zone

resource "aws_route53_record" "service_route53_record" {
  zone_id = "${data.terraform_remote_state.domains.public_zone_id}"
  name    = "${var.dns_prefix}"
  type    = "${var.dns_type}"
  ttl     = "${var.dns_ttl}"
  records = ["${var.alb_dns_name}"]
}
