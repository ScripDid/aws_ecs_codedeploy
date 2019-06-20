resource "aws_lambda_event_source_mapping" "scale_in_lambda_fn_sqs_mapping" {
  event_source_arn = "${aws_sqs_queue.scale_in_lambda_fn_queue.arn}"
  function_name    = "${aws_lambda_function.scale_in_lambda_function.arn}"
}

resource "aws_sqs_queue" "scale_in_lambda_fn_queue" {
  name                      = "sqs-${var.app_env}-${var.application}-${var.cluster_function}_queue_for_blue_green_scale_in"
  delay_seconds             = 600
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10

  # redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.terraform_queue_deadletter.arn}\",\"maxReceiveCount\":4}"
  visibility_timeout_seconds = 60
  tags                       = "${var.tags}"
}
