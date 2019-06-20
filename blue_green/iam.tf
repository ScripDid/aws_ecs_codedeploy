resource "aws_iam_role" "ecs_blue_green_scale_out_role" {
  name        = "role-${var.app_env}-${var.application}-${var.cluster_function}_ecs_blue_green_scale_out"
  description = "Role for Lambda's blue/green scale in function"
  path        = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ecs_blue_green_scale_out_iam_policy" {
  name        = "policy-${var.app_env}-${var.application}-${var.cluster_function}_ecs_blue_green_scale_out"
  path        = "/"
  description = "Policy for Lambda blue/green scale out"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "sqs:SendMessage"
        ],
        "Effect": "Allow",
        "Resource": "${aws_sqs_queue.scale_in_lambda_fn_queue.arn}"
      },
      {
        "Action": [
          "ecs:DescribeClusters"
        ],
        "Effect": "Allow",
        "Resource": "${var.cluster_arn}"
      },
      {
        "Action": [
          "ecs:ListClusters"
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Action": [
          "ecs:DescribeServices",
          "ecs:ListServices"
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Action": [
          "ecs:DescribeContainerInstances",
          "ecs:ListContainerInstances",
          "ecs:ListTaskDefinitions",
          "ecs:UpdateContainerInstancesState"
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Action": [
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:UpdateAutoScalingGroup"
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Action": [
          "ssm:PutParameter",
          "ssm:GetParameter"
        ],
        "Effect": "Allow",
        "Resource": "${aws_ssm_parameter.blue_green_ssm_param.arn}"
      }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_blue_green_scale_out_policy_attachment" {
  role       = "${aws_iam_role.ecs_blue_green_scale_out_role.name}"
  policy_arn = "${aws_iam_policy.ecs_blue_green_scale_out_iam_policy.arn}"
}

###############################################################################
#
# IAM CONFIGURATION FOR LAMBDA
#
###############################################################################

resource "aws_iam_role" "ecs_blue_green_scale_in_role" {
  name        = "role-${var.app_env}-${var.application}-${var.cluster_function}_ecs_blue_green_scale_in"
  description = "Role for Lambda's blue/green scale in function"
  path        = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ecs_blue_green_scale_in_iam_policy" {
  name        = "policy-${var.app_env}-${var.application}-${var.cluster_function}_ecs_blue_green_scale_in"
  path        = "/"
  description = "Policy for Lambda blue/green scale in"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPushLogsInCloudWatch",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:UpdateAutoScalingGroup"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_blue_green_scale_in_iam_role_policy_attachment" {
  role       = "${aws_iam_role.ecs_blue_green_scale_in_role.name}"
  policy_arn = "${aws_iam_policy.ecs_blue_green_scale_in_iam_policy.arn}"
}

resource "aws_iam_policy" "ecs_blue_green_scale_in_sqs_iam_policy" {
  name        = "policy-${var.app_env}-${var.application}-${var.cluster_function}_sqs_ecs_blue_green_scale_in"
  path        = "/"
  description = "Policy for Lambda blue/green scale in to pull messages from SQS queue"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPushLogsInCloudWatch",
      "Action": [
        "sqs:ChangeMessageVisibility",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:ReceiveMessage"
      ],
      "Effect": "Allow",
      "Resource": "${aws_sqs_queue.scale_in_lambda_fn_queue.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_blue_green_scale_in_sqs_iam_role_policy_attachment" {
  role       = "${aws_iam_role.ecs_blue_green_scale_in_role.name}"
  policy_arn = "${aws_iam_policy.ecs_blue_green_scale_in_sqs_iam_policy.arn}"
}
