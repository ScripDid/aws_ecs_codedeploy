resource "aws_appautoscaling_target" "ecs_service_app_auto_scaling" {
  count              = "${var.scheduling_strategy == "REPLICA" ? 1 : 0 }"
  max_capacity       = "${var.autoscaling_maxcapacity}"
  min_capacity       = "${var.autoscaling_mincapacity}"
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.service_ecs_service.name}"
  role_arn           = "${data.aws_iam_role.ecs_service.arn}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "service_cpu_memory_scale_in_policy" {
  count              = "${var.scheduling_strategy == "REPLICA" ? 1 : 0 }"
  name               = "asp-${var.owner}-${var.appliation}-${var.service_name}_service_cpu_mem_scalein"
  policy_type        = "StepScaling"
  resource_id        = "${aws_appautoscaling_target.ecs_service_app_auto_scaling.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.ecs_service_app_auto_scaling.scalable_dimension}"
  service_namespace  = "${aws_appautoscaling_target.ecs_service_app_auto_scaling.service_namespace}"
  depends_on         = ["aws_appautoscaling_target.ecs_service_app_auto_scaling"]

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

resource "aws_appautoscaling_policy" "service_cpu_scaleout_appautoscaling_policy" {
  count              = "${var.scheduling_strategy == "REPLICA" ? 1 : 0 }"
  name               = "asp-${var.owner}-${var.appliation}-${var.service_name}_service_cpu_scaleout"
  policy_type        = "StepScaling"
  resource_id        = "${aws_appautoscaling_target.ecs_service_app_auto_scaling.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.ecs_service_app_auto_scaling.scalable_dimension}"
  service_namespace  = "${aws_appautoscaling_target.ecs_service_app_auto_scaling.service_namespace}"
  depends_on         = ["aws_appautoscaling_target.ecs_service_app_auto_scaling"]

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Minimum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "service_memory_scaleout_appautoscaling_policy" {
  count              = "${var.scheduling_strategy == "REPLICA" ? 1 : 0 }"
  name               = "asp-${var.owner}-${var.appliation}-${var.service_name}_service_memory_scaleout"
  policy_type        = "StepScaling"
  resource_id        = "${aws_appautoscaling_target.ecs_service_app_auto_scaling.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.ecs_service_app_auto_scaling.scalable_dimension}"
  service_namespace  = "${aws_appautoscaling_target.ecs_service_app_auto_scaling.service_namespace}"
  depends_on         = ["aws_appautoscaling_target.ecs_service_app_auto_scaling"]

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Minimum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}
