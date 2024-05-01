variable "vpc_id" {
  type        = string
  description = "VPC ID for the VPC whose private subnets will host the application"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "namespace" {
  type        = string
  description = "Namespace name"
}

variable "target_group_arn" {
  type        = string
  description = "ARN of the target group to register the service with"
}

variable "image_tag" {
  type        = string
  default     = "latest"
  description = "Version of the application image to deploy"
}

variable "service_security_group_id" {
  type        = string
  description = "Security group to associate with the service"
  default     = ""
}

variable "mp_subnet_prefix" {
  description = "Prefix for subnet names"
  type        = string
  default     = "hmpps-development"
}


variable "efs_id" {
  description = "EFS ID"
  type        = string
}

variable "efs_access_point_id" {
  description = "EFS Access Point ID"
  type        = string
}

variable "slapd_log_level" {
  description = "slapd log level"
  type        = string
  default     = "stats"
}

variable "ecs_task_cpu" {
  type        = number
  description = "The number of CPU units used by the task. If using FARGATE launch type task_cpu must match supported memory values [https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size]"
}

variable "ecs_task_memory" {
  type        = number
  description = "The amount of memory (in MiB) used by the task. If using Fargate launch type task_memory must match supported cpu values [https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size]"
}

variable "ecs_desired_task_count" {
  type        = number
  description = "Number of desired ECS tasks"
}

variable "deployment_minimum_healthy_percent" {
  type        = number
  description = "The lower limit (as a percentage of `desired_count`) of the number of tasks that must remain running and healthy in a service during a deployment"
  default     = 0
}

variable "deployment_maximum_percent" {
  type        = number
  description = "The upper limit of the number of tasks (as a percentage of `desired_count`) that can be running in a service during a deployment"
  default     = 100
}