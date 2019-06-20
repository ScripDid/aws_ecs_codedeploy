# SCALE OUT
resource "aws_cloudwatch_log_group" "blue_green_scale_out_fct_cw_log_group" {
  name              = "/aws/lambda/lbd-${var.app_env}-${var.application}-${var.cluster_function}_ecs_blue_green_scale_out"
  retention_in_days = "${var.cloudwatch_retention}"

  tags = "${merge(
    map(
      "Description", "Cloudfront log group for blue/green scale out"
    ),
    "${var.tags}"
  )}"
}

resource "aws_cloudwatch_event_rule" "ecs_blue_green_scale_out_ecs-service_event_rule" {
  name        = "cer-${var.app_env}-${var.application}-${var.cluster_function}_svc_change_ecs_blue_green_scale_out"
  description = "Event Rule for Lambda function blue/green scale out"
  is_enabled  = true

  event_pattern = <<PATTERN
{
  "source": [
    "aws.ecs"
  ],
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "responseElements": {
        "taskDefinition": {
          "family" : [
            "td-${var.app_env}-${var.application}-${var.service_name}"
          ]
      }
    },
    "eventSource": [
      "ecs.amazonaws.com"
    ],
    "eventName": [
      "DeregisterTaskDefinition"
    ]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_rule" "ecs_blue_green_scale_out_ecs-task_event_rule" {
  name        = "cer-${var.app_env}-${var.application}-${var.cluster_function}_task_change_ecs_blue_green_scale_out"
  description = "Event Rule for Lambda function blue/green scale out"
  is_enabled  = true

  event_pattern = <<PATTERN
{
  "source": [
    "aws.ecs"
  ],
  "detail-type": [
    "ECS Task State Change"
  ],
  "detail": {
    "clusterArn": [
      "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/ecs-${var.app_env}-${var.application}-${var.cluster_function}"
    ]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "blue_green_scale_out_service_event_fn_target" {
  depends_on = ["aws_lambda_function.scale_out_lambda_function"]
  arn        = "${aws_lambda_function.scale_out_lambda_function.arn}"
  rule       = "${aws_cloudwatch_event_rule.ecs_blue_green_scale_out_ecs-service_event_rule.name}"
  target_id  = "ScaleOutServiceEventTarget"
}

resource "aws_cloudwatch_event_target" "blue_green_scale_out_task_event_fn_target" {
  depends_on = ["aws_lambda_function.scale_out_lambda_function"]
  arn        = "${aws_lambda_function.scale_out_lambda_function.arn}"
  rule       = "${aws_cloudwatch_event_rule.ecs_blue_green_scale_out_ecs-task_event_rule.name}"
  target_id  = "ScaleOutTaskEventTarget"
}

# SCALE IN

resource "aws_cloudwatch_log_group" "blue_green_scale_in_fct_cw_log_group" {
  name              = "/aws/lambda/lbd-${var.app_env}-${var.application}-${var.cluster_function}_ecs_blue_green_scale_in"
  retention_in_days = 30

  tags = "${merge(
    map(
      "Description", "Cloudfront log group for blue/green scale in"
    ),
    "${var.tags}"
  )}"
}
