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

variable "s3_bucket_name" {
  type        = string
  default     = "latest"
  description = "s3 bucket name for app"
}

variable "service_security_group_id" {
  type        = string
  description = "Security group to associate with the service"
  default     = ""
}


variable "test_container" {
  default     = false
  description = "Whether or not to deploy the ldap load test container"
}


variable "cluster_arn" {
  description = "Cluster ARN"
  type        = string
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


variable "s3_migration_seed_uri" {
  description = "S3 Migration Seed URI"
  type        = string
}
