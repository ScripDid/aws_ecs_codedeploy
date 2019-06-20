variable "region" {
  description = "The hosting AWS region"
  default     = "eu-west-1"
}

variable "owner" {
  description = "AWS account's owner"
  default     = "ADIKTS"
}

variable "operator" {
  description = "The one who deploys the AWS resoources"
  default     = "Didier ZOLA"
}

variable "application" {
  description = "Application Name"
  default     = "ecs-codedeploy"
}

# REMOTE STATES

variable "tfstate_bucket" {
  description = ""
  default     = "adikts-tfstates-bucket"
}

variable "foundation_tfstate_key" {
  description = ""
  default     = "foundation/main.tfstate"
}

variable "buckets_prefix" {
  description = "Default bucket prefix"
  default     = "adikts-bucket"
}

# ALB
variable "bool_alb_internal" {
  description = ""
  default     = false
}

variable "load_balancer_type" {
  description = ""
  default     = "application"
}

# ASG

variable "ami_id" {
  description = "The ID of the AMI to deploy in the auto scaling group dedicated to the ECS cluster. The current Amazon ECS-optimized Amazon Linux 2 AMI (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html & https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/finding-an-ami.html)"
  default     = "ami-09cd8db92c6bf3a84"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "ec2_key_pair_name" {
  description = "The key name that should be used for the instance"
  default     = "KP_ADIKTS_20190415"
}

variable "max_size" {
  description = "Maximum size of the nodes in the cluster"
  default     = 2
}

variable "min_size" {
  description = "Minimum size of the nodes in the cluster"
  default     = 1
}

variable "asg_hcheck_grace_period" {
  description = "Time an EC2 instance is allowed to be down"
  default     = 60
}

variable "desired_capacity" {
  description = "The desired capacity of the cluster"
  default     = 1
}

variable "min_success_instances_percent" {
  description = "The percentage of instances in an Auto Scaling rolling update that must signal success for an update to succeed"
  default     = 100
}

variable "ecs_instance_additional_security_groups" {
  default     = []
  description = "Additional security group to the ecs instances"
  type        = "list"
}

variable "scaling_adjustment" {
  description = "The number of instances by which to scale. adjustment_type determines the interpretation of this number"
  default     = 1
}

variable "cooldown_duration" {
  description = "The amount of time, in seconds, after a scaling activity completes and before the next scaling activity can start"
  default     = 60
}

variable "scaling_period_count" {
  description = "The number of periods over which data is compared to the specified threshold"
  default     = 2
}

variable "scaling_period" {
  description = "The period in seconds over which the specified statistic is applied"
  default     = 60
}

variable "scale_out_memory_threshold" {
  description = "Memory reservation threshold in percentage for scaling out"
  default     = 70
}

variable "scale_in_memory_threshold" {
  description = "Memory reservation threshold in percentage for scaling in"
  default     = 30
}

variable "scaling_out_cpu_threshold" {
  description = "CPU reservation threshold in percentage for scaling out"
  default     = 70
}

variable "scaling_in_threshold" {
  description = "Reservation threshold in percentage for scaling in"
  default     = 70
}

# CLOUDWATCH

variable "retention_days" {
  description = "Specifies the number of days you want to retain log events in the specified log group\nValid values are: [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653]"
  default     = 14
}

#================ Landing Zone Variables =================

variable "environment" {
  description = "Environment name, should be DEV,INT,UAT,PROD"
  default     = "dev"
}

variable "cluster_function" {
  description = "What your cluster does, backend, frontend, main ..."
  default     = "main"
}

variable "ECS_check_grace_period" {
  description = "Time an EC2 instance is allowed to be down"
  default     = 300
}

## SERVICE ##
variable "host_port" {
  description = "The port number on the container instance to reserve for your container. For dynamic mapping use 0."
  default     = 0
}

variable "container_port" {
  description = "The listen port inside the container, this port will be mapped to the service port on the host"
  default     = "8080"
}

variable "image_tag" {
  description = "Image tag"
  default     = "latest"
}

variable "image" {
  description = "Image repository"
  default     = "tomcat"
}

#### Other Service variables ####

variable "service_name" {
  description = "Name of the ECS service"
  default     = "main"
}

variable "alb_protocol" {
  description = "The ALB Listener protocol, must be HTTPS"
  default     = "HTTPS"
}

variable "container_protocol" {
  description = "Protocol used on target group to reach the container."
  default     = "HTTP"
}

variable "health_check_protocol" {
  description = "Protocol used on health check to tags the container as healthy."
  default     = "HTTP"
}

variable "health_check_matcher" {
  description = "Word to check on health check response."
  default     = "200"
}

variable "health_check_path" {
  description = "The path of the URL on health check"
  default     = "/"
}

variable "deregistration_delay" {
  description = "Time in seconds before remove the container in target group"
  default     = "300"
}

variable "service_port" {
  description = "The service port. Be careful to not used a port already used by another service !"
  default     = "443"
}

variable "dns_rr_type" {
  description = "The record type. Valid values are A, AAAA, CAA, CNAME, MX, NAPTR, NS, PTR, SOA, SPF, SRV and TXT."
  default     = "CNAME"
}

variable "dns_rr_ttl" {
  description = "The TTL of the record."
  default     = 5
}

variable "desired_count" {
  description = "The number of instances of the task definition to place and keep running."
  default     = 1
}

variable "min_health_percent" {
  description = "The lower limit (as a percentage of the service's desiredCount) of the number of running tasks that must remain running and healthy in a service during a deployment."
  default     = 50
}

variable "max_health_percent" {
  description = "The upper limit (as a percentage of the service's desiredCount) of the number of running tasks that can be running in a service during a deployment."
  default     = 200
}

variable "listener_default_action_type" {
  description = "The type of routing action. Valid values are forward, redirect, fixed-response, authenticate-cognito and authenticate-oidc."
  default     = "forward"
}

variable "listener_ssl_policy" {
  description = "The name of the SSL Policy for the listener. Required if protocol is HTTPS."
  default     = "ELBSecurityPolicy-2016-08"
}

variable "tg_sticky_type" {
  description = "The type of sticky sessions. The only current possible value is lb_cookie"
  default     = "lb_cookie"
}

variable "container_cpu" {
  description = "Number of virtual CPU reserved for a container"
  default     = 512
}

variable "container_memory" {
  description = "Amount of memory reservation (in MiB) for a container"
  default     = 1024
}

variable "container_memory_reservation" {
  description = "Amount of memory reservation (in MiB) for a container"
  default     = 128
}

variable "data_points" {
  description = "The number of datapoints that must be breaching to trigger the alarm"
  default     = 1
}

variable "scheduling_strategy" {
  description = "The scheduling strategy to use for the service. The valid values are REPLICA and DAEMON."
  default     = "REPLICA"
}

variable "autoscaling_maxcapacity" {
  description = "Maximum service desired count adjustement by autoscaling"
  default     = 50
}

variable "autoscaling_mincapacity" {
  description = "Minimum service desired count adjustement by autoscaling"
  default     = 1
}

variable "hcheck_unhealthy_threshold" {
  description = "The number of consecutive health check failures required before considering the target unhealthy"
  default     = 3
}

variable "health_check_timeout" {
  description = "The amount of time, in seconds, during which no response means a failed health check. For Application Load Balancers, the range is 2 to 60 seconds and the default is 5 seconds"
  default     = 5
}

variable "health_check_interval" {
  description = "The approximate amount of time, in seconds, between health checks of an individual target"
  default     = 30
}

variable "health_check_threshold" {
  description = "The number of consecutive health checks successes required before considering an unhealthy target healthy. Defaults to 3"
  default     = 3
}

variable "deployment_controller" {
  description = "Type of deployment controller. Valid values: CODE_DEPLOY, ECS."
  default     = "ECS"
}

variable "ordered_placement_strategy" {
  type        = "list"
  description = "Ordered task placement strategy on EC2 instances"

  default = [
    {
      type  = "spread"
      field = "attribute:ecs.availability-zone"
    },
    {
      type  = "spread"
      field = "instanceId"
    },
  ]
}

variable "dns_hostname" {
  description = "The name of the Route 53 DNS record"
  default     = "www"
}

variable "dns_ttl" {
  description = "(Required for non-alias records) The TTL of the record"
  default     = 60
}

variable "r53_zone_id" {
  description = "The ID of the Route 53 zone to use"
  default     = ""
}

variable "acm_cert_validation_method" {
  description = "The method used to validate the certificate"
  default     = "DNS"
}

variable "dns_domain_name" {
  description = "DNS domain name"
  default     = "adikts.net."
}

variable "alb_port_range_FROM" {
  description = "Port from where to open on ALB"
  default     = "443"
}

variable "alb_port_range_TO" {
  description = "Port to where to open on ALB"
  default     = "443"
}

variable "alb_ingress_cidr_block" {
  default = ["0.0.0.0/0"]
}


variable "ecs_sg_port_range_from" {
  description = "Port from where to open EC2 Instances Security Group. Default to dynamic port."
  default     = "32768"
}

variable "ecs_sg_port_range_to" {
  description = "Port to where to open EC2 Instances Security Group. Default to dynamic port."
  default     = "61000"
}
