data "template_file" "user_data_template_file" {
  template = "${file("./templates/multipart_amz_lnx2_user_data.sh")}"

  vars {
    additional_commands = "${data.template_file.additional_commands.rendered}"
    additional_logs     = "${data.template_file.aws_logs_conf.rendered}"
    cluster             = "ecs-${var.environment}-${var.application}-${var.cluster_function}"
    cfn_stack_name      = "cfs-${var.owner}-${var.application}"
    cfn_stack_region    = "${var.region}"
  }
}

data "template_file" "additional_commands" {
  template = "${file("./templates/additional_commands.sh")}"
}

data "template_file" "aws_logs_conf" {
  template = "${file("./templates/awslogs.conf")}"
}

locals {
  autoscaling_group_tags = "${merge(local.mandatory_tags,map("Name","asg-${var.owner}-${var.application}"))}"
}

data "null_data_source" "tags" {
  count = "${length(keys(local.autoscaling_group_tags))}"

  inputs = {
    "Key"               = "${element(keys(local.autoscaling_group_tags), count.index)}"
    "Value"             = "${element(values(local.autoscaling_group_tags), count.index)}"
    "PropagateAtLaunch" = "true"
  }
}

resource "aws_cloudformation_stack" "asg_cloudformation_stack" {
  name       = "cfs-${var.owner}-${var.application}"
  on_failure = "DELETE"

  template_body = <<EOF
{
  "Description" : "Auto scaling group for ecs instances mangement",
  "Resources" : {
    "ASG" : {
      "Type" : "AWS::AutoScaling::AutoScalingGroup",
      "Properties" : {
        "AutoScalingGroupName" : "asg-${var.owner}-${var.application}",
        "MaxSize" : "${var.max_size}",
        "MinSize" : "${var.min_size}",
        "HealthCheckGracePeriod" : "${var.asg_hcheck_grace_period}",
        "DesiredCapacity" : "${var.desired_capacity}",
        "LaunchConfigurationName" : "${aws_launch_configuration.launch_configuration.id}",
        "VPCZoneIdentifier" : ["${join(",", data.terraform_remote_state.foundation.private_subnets_list)}"],
        "Tags" : ${replace(jsonencode(data.null_data_source.tags.*.outputs), "\"PropagateAtLaunch\":\"1\"",
"\"PropagateAtLaunch\":\"true\"")}
      },
      "CreationPolicy" : {
        "AutoScalingCreationPolicy" : { "MinSuccessfulInstancesPercent" : "${var.min_success_instances_percent}" },
        "ResourceSignal" : { "Timeout" : "PT5M" }
      },
      "UpdatePolicy" : {
        "AutoScalingScheduledAction" : { "IgnoreUnmodifiedGroupSizeProperties" : "true" },
        "AutoScalingRollingUpdate" : {
          "MaxBatchSize" : "${var.max_size / 2}",
          "MinInstancesInService" : "${var.min_size}",
          "MinSuccessfulInstancesPercent" : 100,
          "PauseTime" : "PT5M",
          "SuspendProcesses" : [
            "HealthCheck",
            "ReplaceUnhealthy",
            "AZRebalance",
            "AlarmNotification",
            "ScheduledActions"
          ],
          "WaitOnResourceSignals" : true
        }
      },
      "DeletionPolicy" : "Delete"
    }
  },
  "Outputs" : {
    "asgName" : {
      "Description" : "ASG name",
      "Value": "asg-${var.owner}-${var.application}"
    }
  }
}
EOF
}

resource "aws_launch_configuration" "launch_configuration" {
  name_prefix   = "lc-${var.owner}-${var.application}"
  image_id      = "${var.ami_id}"
  instance_type = "${var.instance_type}"

  security_groups = ["${concat(list(aws_security_group.ecs_instance_security_group.id),
                             compact(var.ecs_instance_additional_security_groups))}"]

  user_data            = "${data.template_file.user_data_template_file.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.ecs_iam_instance_profile.id}"
  key_name             = "${var.ec2_key_pair_name}"

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    "aws_cloudwatch_log_group.audit_cloudwatch_log_group",
    "aws_cloudwatch_log_group.dmesg_cloudwatch_log_group",
    "aws_cloudwatch_log_group.docker_cloudwatch_log_group",
    "aws_cloudwatch_log_group.ecs-agent_cloudwatch_log_group",
    "aws_cloudwatch_log_group.ecs-init_cloudwatch_log_group",
    "aws_cloudwatch_log_group.messages_cloudwatch_log_group",
  ]
}
