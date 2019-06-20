resource "aws_cloudwatch_log_group" "dmesg_cloudwatch_log_group" {
  name              = "cwlg-${var.owner}-${var.application}/var/log/dmesg"
  retention_in_days = "${var.retention_days}"
}

resource "aws_cloudwatch_log_group" "docker_cloudwatch_log_group" {
  name              = "cwlg-${var.owner}-${var.application}/var/log/docker"
  retention_in_days = "${var.retention_days}"
}

resource "aws_cloudwatch_log_group" "ecs-agent_cloudwatch_log_group" {
  name              = "cwlg-${var.owner}-${var.application}/var/log/ecs/ecs-agent.log"
  retention_in_days = "${var.retention_days}"
}

resource "aws_cloudwatch_log_group" "ecs-init_cloudwatch_log_group" {
  name              = "cwlg-${var.owner}-${var.application}/var/log/ecs/ecs-init.log"
  retention_in_days = "${var.retention_days}"
}

resource "aws_cloudwatch_log_group" "audit_cloudwatch_log_group" {
  name              = "cwlg-${var.owner}-${var.application}/var/log/ecs/audit.log"
  retention_in_days = "${var.retention_days}"
}

resource "aws_cloudwatch_log_group" "messages_cloudwatch_log_group" {
  name              = "cwlg-${var.owner}-${var.application}/var/log/messages"
  retention_in_days = "${var.retention_days}"
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory_scaling_out_cloudwatch_alarm" {
  alarm_name                = "cwal-${var.owner}-${var.application}_cluster_memory_scale_out"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "${var.scaling_period_count}"
  metric_name               = "MemoryUtilization"
  namespace                 = "AWS/ECS"
  period                    = "${var.scaling_period}"
  statistic                 = "Average"
  threshold                 = "${var.scale_out_memory_threshold}"
  alarm_description         = "Triggers an ECS service scale out based on the ECS cluster's Memory Utilization"
  insufficient_data_actions = []

  dimensions {
    ClusterName = "ecs-${var.owner}-${var.application}"
  }

  alarm_actions = ["${aws_autoscaling_policy.memory_out_autoscaling_policy.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_scaling_out_cloudwatch_alarm" {
  alarm_name                = "cwal-${var.owner}-${var.application}_cluster_cpu_out_scale"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "${var.scaling_period_count}"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/ECS"
  period                    = "${var.scaling_period}"
  statistic                 = "Average"
  threshold                 = "${var.scaling_out_cpu_threshold}"
  alarm_description         = "Triggers an ECS service scale out based on the ECS cluster's CPU Utilization"
  insufficient_data_actions = []

  dimensions {
    ClusterName = "ecs-cluster-${var.owner}-${var.application}"
  }

  alarm_actions = ["${aws_autoscaling_policy.cpu_out_autoscaling_policy.arn}"]
}

#resource "aws_cloudwatch_metric_alarm" "ecs_cpu_mem_in_autoscaling_metric_alarm" {
#  alarm_name                = "cal-${var.owner}-${var.application}_cluster_cpu_mem_in_scale"
#  comparison_operator       = "LessThanOrEqualToThreshold"
#  evaluation_periods        = "${var.scaling_period_count}"
#  threshold                 = "${var.scaling_in_threshold}"
#  alarm_description         = "This metric monitors ecs instance cpu and memory utilization reservation for in scaling"
#  insufficient_data_actions = []
#
#  metric_query {
#    id          = "e1"
#    expression  = "MAX(METRICS())"
#    label       = "CPU_Memory Utilization"
#    return_data = "true"
#  }
#
#  metric_query {
#    id = "m1"
#
#    metric {
#      metric_name = "CPUUtilization"
#      namespace   = "AWS/ECS"
#      period      = "${var.scaling_period}"
#      stat        = "Average"
#      unit        = "Percent"
#
#      dimensions = {
#        ClusterName = "ecs-${var.owner}-${var.application}"
#      }
#    }
#  }
#
#  metric_query {
#    id = "m2"
#
#    metric {
#      metric_name = "MemoryUtilization"
#      namespace   = "AWS/ECS"
#      period      = "${var.scaling_period}"
#      stat        = "Average"
#      unit        = "Percent"
#
#      dimensions = {
#        ClusterName = "ecs-${var.owner}-${var.application}"
#      }
#    }
#  }
#
#  alarm_actions = ["${aws_autoscaling_policy.cpu_mem_in_autoscaling_policy.arn}"]
#}

resource "aws_cloudformation_stack" "ecs_scaling_in_cloudwatch_alarm" {
  name = "cfs-${var.owner}-${var.application}ClusterInCloudwatchMetricAlarm"

  template_body = <<EOF
   {
     "Description" : "Cloudwatch Alarm for service scale in",
     "Resources" : {
       "CWA" : {
         "Type" : "AWS::CloudWatch::Alarm",
         "Properties" : {
           "AlarmActions" : ["${aws_autoscaling_policy.cpu_mem_in_autoscaling_policy.arn}"],
           "AlarmDescription" : "Triggers anan ECS service scale in based on the ECS cluster's CPU & Memory Reservation",
           "AlarmName" : "cal-${var.owner}-${var.application}_cluster_cpu_mem_in_scale",
           "ComparisonOperator" : "LessThanOrEqualToThreshold",
           "EvaluationPeriods" : "${var.scaling_period_count}",
           "Metrics" : [
             {
               "Expression": "MAX(METRICS())",
               "ReturnData": true,
               "Label": "MAX",
               "Id": "e1"
             },
             {
               "ReturnData": false,
               "MetricStat": {
                 "Period": "${var.scaling_period}",
                 "Stat": "Average",
                 "Metric": {
                   "Namespace": "AWS/ECS",
                   "Dimensions": [
                     {
                       "Name": "ServiceName",
                       "Value": "ecs-${var.owner}-${var.application}"
                     }
                   ],
                   "MetricName": "CPUReservation"
                 }
               },
               "Id": "m1"
             },
             {
               "ReturnData": false,
               "MetricStat": {
                 "Period": "${var.scaling_period}",
                 "Stat": "Average",
                 "Metric": {
                   "Namespace": "AWS/ECS",
                   "Dimensions": [
                     {
                       "Name": "ServiceName",
                       "Value": "ecs-${var.owner}-${var.application}"
                     }
                   ],
                   "MetricName": "MemoryReservation"
                 }
               },
               "Id": "m2"
             }
           ],
           "Threshold" : "${var.scaling_in_threshold}"
         },
         "DeletionPolicy" : "Delete"
       }
     }
   }
   EOF
}

##
# ECS service
###
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_scale_out_cloudwatch_alarm" {
  alarm_description         = "This metric monitors ecs instance memory utilization for out scaling"
  alarm_name                = "cal-${var.owner}-${var.appliation}-${var.service_name}_service_memory_out_scale"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  count                     = "${var.scheduling_strategy == "REPLICA" ? 1 : 0 }"
  evaluation_periods        = "${var.scaling_number_period}"
  insufficient_data_actions = []
  metric_name               = "MemoryUtilization"
  namespace                 = "AWS/ECS"
  period                    = "${var.scaling_period}"
  statistic                 = "Average"
  threshold                 = "${var.scaling_out_memory_threshold}"

  dimensions {
    ClusterName = "${var.cluster_name}"
    ServiceName = "${var.service_name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.service_memory_scaleout_appautoscaling_policy.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_autoscaling_out_cloudwatch_metric_alarm" {
  count                     = "${var.scheduling_strategy == "REPLICA" ? 1 : 0 }"
  alarm_name                = "cal-${var.owner}-${var.appliation}-${var.service_name}_service_cpu_out_scale"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "${var.scaling_number_period}"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/ECS"
  period                    = "${var.scaling_period}"
  statistic                 = "Average"
  threshold                 = "${var.scaling_out_cpu_threshold}"
  alarm_description         = "This metric monitors ecs instance cpu utilization for out scaling"
  insufficient_data_actions = []

  dimensions {
    ClusterName = "${var.cluster_name}"
    ServiceName = "${var.service_name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.service_cpu_scaleout_appautoscaling_policy.arn}"]
}

# resource "aws_cloudwatch_metric_alarm" "ecs_cpu_mem_in_autoscaling_metric_alarm" {
#   alarm_name                = "cal-${var.owner}-${var.appliation}-${var.service_name}_service_cpu_mem_in_scale"
#   comparison_operator       = "LessThanOrEqualToThreshold"
#   evaluation_periods        = "${var.scaling_number_period}"
#   threshold                 = "${var.scaling_in_threshold}"
#   alarm_description         = "This metric monitors ecs instance cpu and memory utilization reservation for in scaling"
#   insufficient_data_actions = []

#   metric_query {
#         id = "e1"
#         expression = "MAX(METRICS())"
#         label = "CPU_Memory Utilization MAX"
#         return_data = "true"
#     }
#     metric_query {
#         id = "m1"
#         metric {
#             metric_name = "CPUUtilization"
#             namespace   = "AWS/ECS"
#             period      = "${var.scaling_period}"
#             stat        = "Average"
#             unit        = "Percent"
#             dimensions {
#                 ServiceName = "${var.service_name}"
#                 # ClusterName = "${var.cluster_name}"
#             }
#         }
#     }
#     metric_query {
#         id = "m2"
#         metric {
#             metric_name = "MemoryUtilization"
#             namespace   = "AWS/ECS"
#             period      = "${var.scaling_period}"
#             stat        = "Average"
#             unit        = "Percent"
#             dimensions {
#               # ServiceName = "${var.service_name}"
#               ClusterName = "${var.cluster_name}"
#             }
#         }
#     }

#   alarm_actions = ["${aws_appautoscaling_policy.service_cpu_memory_scale_in_policy.arn}"]
# }

resource "aws_cloudformation_stack" "ecs_service_autoscaling_in_cloudwatch_metric_alarm" {
  count = "${var.scheduling_strategy == "REPLICA" ? 1 : 0 }"
  name  = "cfs-${var.owner}-${var.appliation}-${var.service_name}ServiceInCloudwatchMetricAlarm"

  template_body = <<EOF
  {
    "Description" : "Cloudwatch Alarm for service scale in",
    "Resources" : {
      "CWA" : {
        "Type" : "AWS::CloudWatch::Alarm",
        "Properties" : {
          "AlarmActions" : ["${aws_appautoscaling_policy.service_cpu_memory_scale_in_policy.arn}"],
          "AlarmDescription" : "This metric monitors ecs service cpu and memory utilization for in scaling",
          "AlarmName" : "cal-${var.owner}-${var.appliation}-${var.service_name}_service_cpu_mem_in_scale",
          "DatapointsToAlarm" : "${var.data_points}",
          "ComparisonOperator" : "LessThanOrEqualToThreshold",
          "EvaluationPeriods" : "${var.scaling_number_period}",
          "Metrics" : [
            {
              "Expression": "MAX(METRICS())",
              "ReturnData": true,
              "Label": "MAX",
              "Id": "e1"
            },
            {
              "ReturnData": false,
              "MetricStat": {
                "Period": "${var.scaling_period}",
                "Stat": "Average",
                "Metric": {
                  "Namespace": "AWS/ECS",
                  "Dimensions": [
                    {
                      "Name": "ClusterName",
                      "Value": "${var.cluster_name}"
                    },
                    {
                      "Name": "ServiceName",
                      "Value": "${var.service_name}"
                    }
                  ],
                  "MetricName": "CPUUtilization"
                }
              },
              "Id": "m1"
            },
            {
              "ReturnData": false,
              "MetricStat": {
                "Period": "${var.scaling_period}",
                "Stat": "Average",
                "Metric": {
                  "Namespace": "AWS/ECS",
                  "Dimensions": [
                    {
                      "Name": "ClusterName",
                      "Value": "${var.cluster_name}"
                    },
                    {
                      "Name": "ServiceName",
                      "Value": "${var.service_name}"
                    }
                  ],
                  "MetricName": "MemoryUtilization"
                }
              },
              "Id": "m2"
            }
          ],
          "Threshold" : "${var.scaling_in_threshold}"
        },
        "DeletionPolicy" : "Delete"
      }
    }
  }
  EOF
}
