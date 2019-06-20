resource "aws_iam_role" "ecs_instance_iam_role" {
  name        = "role-${var.owner}-${var.application}_inst"
  description = "IAM role for ${var.application} container instance"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ec2.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ecs_iam_instance_profile" {
  name = "ec2-instance-profile-${var.owner}-${var.application}"
  path = "/"
  role = "${aws_iam_role.ecs_instance_iam_role.name}"
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_iam_role_policy_attachment" {
  role       = "${aws_iam_role.ecs_instance_iam_role.id}"
  policy_arn = "${aws_iam_policy.ecs_instance_iam_policy.arn}"
}

resource "aws_iam_policy" "ecs_instance_iam_policy" {
  name = "policy-${var.owner}-${var.application}_inst"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecs:DiscoverPollEndpoint",
                "ecr:GetAuthorizationToken",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecs:DeregisterContainerInstance",
                "ecs:RegisterContainerInstance",
                "ecs:SubmitContainerStateChange",
                "ecs:SubmitTaskStateChange"
            ],
            "Resource": "${aws_ecs_cluster.ecs_cluster.id}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecs:Poll",
                "ecs:StartTelemetrySession",
                "ecs:UpdateContainerInstancesState"
            ],
            "Resource": "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:container-instance/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage"
            ],
            "Resource": [
                "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_cloudwatch_iam_role_policy_attachment" {
  role       = "${aws_iam_role.ecs_instance_iam_role.id}"
  policy_arn = "${aws_iam_policy.ecs_cloudwatchlogs_iam_policy.arn}"
}

resource "aws_iam_policy" "ecs_cloudwatchlogs_iam_policy" {
  name        = "policy-${var.owner}-${var.application}_cloudwatchlogs"
  description = "CloudWatch logs policy for ${var.owner} ECS Cluster"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Resource": [
                 "${aws_cloudwatch_log_group.dmesg_cloudwatch_log_group.arn}",
                 "${aws_cloudwatch_log_group.docker_cloudwatch_log_group.arn}",
                 "${aws_cloudwatch_log_group.ecs-agent_cloudwatch_log_group.arn}",
                 "${aws_cloudwatch_log_group.ecs-init_cloudwatch_log_group.arn}",
                 "${aws_cloudwatch_log_group.audit_cloudwatch_log_group.arn}",
                 "${aws_cloudwatch_log_group.messages_cloudwatch_log_group.arn}"
            ]
        }
    ]
}
EOF
}

# Role Policies

resource "aws_iam_role" "ecs_lb_iam_role" {
  name        = "role-${var.owner}-${var.application}_alb"
  description = "Assume role for ${var.owner} Load Balancer"
  path        = "/ecs/"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ecs.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_lb_iam_role_policy_attachment" {
  role       = "${aws_iam_role.ecs_lb_iam_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

### Service Role and policies ###

resource "aws_iam_role" "ecs_service_iam_role" {
  name        = "role-${var.owner}-${var.application}_service"
  description = "Assume role for ${var.owner} ecs service"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ecs.amazonaws.com",
          "ec2.amazonaws.com"
        ]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_service_iam_role_policy" {
  name = "policy-${var.owner}-${var.application}-service"
  role = "${aws_iam_role.ecs_service_iam_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets",
        "ec2:Describe*",
        "ec2:AuthorizeSecurityGroupIngress"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer"
      ],
      "Resource": [
        "${aws_alb.ecs_cluster_alb.arn}"
      ]
    }
  ]
}
EOF
}

data "aws_iam_role" "ecs_service" {
  name = "AmazonECSAutoscaleRole"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "role-${var.environment}-${var.application}-task"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "",
          "Effect": "Allow",
          "Principal": {
              "Service": "ecs-tasks.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
      }
  ]
}
EOF
}
