data "aws_caller_identity" "current" {}

resource "aws_lambda_function" "scale_out_lambda_function" {
  depends_on                     = ["aws_cloudwatch_log_group.blue_green_scale_out_fct_cw_log_group"]
  description                    = "Increase auto scaling desired (and if needed maximum) instance count to implement blue/green deployments"
  filename                       = "${path.module}/templates/ecs_blue_green_scale_out.zip"
  function_name                  = "lbd-${var.app_env}-${var.application}-${var.cluster_function}_ecs_blue_green_scale_out"
  handler                        = "ecs_blue_green_scale_out.lambda_handler"
  memory_size                    = 128
  reserved_concurrent_executions = 1
  role                           = "${aws_iam_role.ecs_blue_green_scale_out_role.arn}"
  runtime                        = "python3.7"
  source_code_hash               = "${data.archive_file.ecs_blue_green_scale_out_file.output_base64sha256}"
  tags                           = "${var.tags}"
  timeout                        = 60

  environment {
    variables = {
      AppShortName = "${var.application}"

      # ServiceName                = "${var.service_name}"
      EcsClusterName = "ecs-${var.app_env}-${var.application}-${var.cluster_function}"
      QueueUrl       = "${aws_sqs_queue.scale_in_lambda_fn_queue.id}"
    }
  }
}

data "archive_file" "ecs_blue_green_scale_out_file" {
  type        = "zip"
  source_file = "${path.module}/templates/ecs_blue_green_scale_out.py"
  output_path = "${path.module}/templates/ecs_blue_green_scale_out.zip"
}

resource "aws_lambda_permission" "ecs_service_events_blue_green_scale_out_fct_perms" {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.scale_out_lambda_function.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.ecs_blue_green_scale_out_ecs-service_event_rule.arn}"
}

resource "aws_lambda_permission" "ecs_task_events_blue_green_scale_out_fct_perms" {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.scale_out_lambda_function.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.ecs_blue_green_scale_out_ecs-task_event_rule.arn}"
}

resource "aws_lambda_function" "scale_in_lambda_function" {
  depends_on                     = ["aws_cloudwatch_log_group.blue_green_scale_in_fct_cw_log_group"]
  description                    = "Decrease auto scaling desired (and if needed maximum) instance count to implement blue/green deployments"
  filename                       = "${path.module}/templates/ecs_blue_green_scale_in.zip"
  function_name                  = "lbd-${var.app_env}-${var.application}-${var.cluster_function}_ecs_blue_green_scale_in"
  handler                        = "ecs_blue_green_scale_in.lambda_handler"
  memory_size                    = "128"
  reserved_concurrent_executions = 1
  role                           = "${aws_iam_role.ecs_blue_green_scale_in_role.arn}"
  runtime                        = "python3.7"
  source_code_hash               = "${data.archive_file.ecs_blue_green_scale_in_file.output_base64sha256}"
  tags                           = "${var.tags}"
  timeout                        = 60

  environment {
    variables = {
      AppShortName = "${var.application}"

      # ServiceName                = "${var.service_name}"
      EcsClusterName = "ecs-${var.app_env}-${var.application}-${var.cluster_function}"
      QueueUrl       = "${aws_sqs_queue.scale_in_lambda_fn_queue.id}"
    }
  }
}

data "archive_file" "ecs_blue_green_scale_in_file" {
  type        = "zip"
  source_file = "${path.module}/templates/ecs_blue_green_scale_in.py"
  output_path = "${path.module}/templates/ecs_blue_green_scale_in.zip"
}

resource "aws_ssm_parameter" "blue_green_ssm_param" {
  description = "SSM parameter to log ECS blue/green operations"
  name        = "/${var.app_env}/${var.application}/${var.service_name}/LastTaskDefThatScaledOutASG"
  overwrite   = true
  type        = "String"
  value       = "Deployed using Terraform"

  lifecycle {
    ignore_changes = [
      # Ignore changes to value, e.g. because a Lambda function
      # updates these based on some ECS lifecycle
      "value",
    ]
  }

  tags = "${local.mandatory_tags}"
}
