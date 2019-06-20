resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-${var.environment}-${var.application}-${var.cluster_function}"
  tags = "${local.mandatory_tags}"
}

data "template_file" "task_definition_template_file" {
  template = "${file("${path.module}/templates/single-task-def.json")}"

  vars {
    # db_address           = "${data.terraform_remote_state.rds.db_address}"
    CLOUDWATCH_LOG_GROUP_DOCKER  = "${aws_cloudwatch_log_group.docker_cloudwatch_log_group.id}"
    CLOUDWATCH_STREAM_PREFIX     = "cls-${var.environment}-${var.application}-${var.cluster_function}"
    CONTAINER_CPU                = "${var.container_cpu}"
    CONTAINER_MEMORY             = "${var.container_memory}"
    CONTAINER_MEMORY_RESERVATION = "${var.container_memory_reservation}"
    CONTAINER_PORT               = "${var.container_port}"
    ENVIRONMENT_NAME             = "${var.environment}"
    HOST_PORT                    = "${var.host_port}"
    IMAGE_TAG                    = "${var.image}:${var.image_tag}"
    APPLICATION                  = "${var.application}"
    REGION                       = "${var.region}"
    TASK_NAME                    = "td-${var.environment}-${var.application}-${var.service_name}"
  }
}

#====> Create the Target Group

resource "aws_alb_target_group" "service_alb_target_group" {
  name                 = "tg-${var.environment}-${var.application}-${var.container_port}"
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
    unhealthy_threshold = "${var.hcheck_unhealthy_threshold}"
    timeout             = "${var.health_check_timeout}"
    interval            = "${var.health_check_interval}"
  }

  stickiness {
    type = "${var.tg_sticky_type}"
  }

  tags = "${local.mandatory_tags}"

  lifecycle {
    create_before_destroy = true
  }
}

#====> Create the ALB Listener for the Target Group

resource "aws_alb_listener" "service_alb_listener" {
  load_balancer_arn = "${aws_alb.ecs_cluster_alb.id}"
  port              = "${var.service_port}"
  protocol          = "${var.alb_protocol}"
  ssl_policy        = "${var.alb_protocol == "HTTPS" ? var.listener_ssl_policy : "" }"

  certificate_arn = "${var.alb_protocol == "HTTPS" ? element(concat(aws_acm_certificate_validation.alb_acm_certificate_validation.*.certificate_arn, list("")), 0) : "" }"

  default_action {
    target_group_arn = "${aws_alb_target_group.service_alb_target_group.id}"
    type             = "${var.listener_default_action_type}"
  }
}

#====> Create the Service

resource "aws_ecs_service" "service_ecs_service" {
  name                               = "${var.service_name}"
  cluster                            = "${aws_ecs_cluster.ecs_cluster.id}"
  deployment_maximum_percent         = "${var.max_health_percent}"
  deployment_minimum_healthy_percent = "${var.min_health_percent}"
  desired_count                      = "${var.desired_count}"
  health_check_grace_period_seconds  = "${var.ECS_check_grace_period}"
  iam_role                           = "${aws_iam_role.ecs_service_iam_role.arn}"
  scheduling_strategy                = "${var.scheduling_strategy}"
  task_definition                    = "${aws_ecs_task_definition.service_ecs_task_definition.arn}"

  deployment_controller {
    type = "${var.deployment_controller}"
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.service_alb_target_group.arn}"
    container_name   = "td-${var.environment}-${var.application}-${var.service_name}"
    container_port   = "${var.container_port}"
  }

  ordered_placement_strategy = "${var.ordered_placement_strategy}"

  # lifecycle {
  #   ignore_changes = ["desired_count"]
  # }
}

resource "aws_ecs_task_definition" "service_ecs_task_definition" {
  family                = "td-${var.environment}-${var.application}-${var.service_name}"
  container_definitions = "${data.template_file.task_definition_template_file.rendered}"

  task_role_arn = "${aws_iam_role.ecs_task_role.arn}"
  depends_on    = ["aws_alb_listener.service_alb_listener"]
}
