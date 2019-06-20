variable "environment" {}

variable "app_env" {
  description = "Environment's name. Used to distinguish many environments in the same AWS account. eg : UATR & UATM."
}

variable "region" {}
variable "costcenter" {}

variable "owner" {
  description = "Who is in charge. Most probably the project"
}

# variable "autoscaling_group_name" {}
variable "application" {
  description = "Application Short Name (application)"
}

variable "cluster_function" {
  description = "What your cluster does, backend, frontend, main ..."
  default     = "main"
}

variable "service_name" {
  description = "Name of the ECS service"
  default     = "portal"
}

variable "cloudwatch_retention" {
  description = "Number of days we want to keep cloudwatch logs."
}

variable "cluster_arn" {
  description = "ARN of the cluster"
}

variable "tags" {
  type        = "map"
  description = "A list of tags to apply to resources that handles it"
}

variable "retention_days" {
  description = "CloudWatch logs retention in days"
  default     = "30"
}
