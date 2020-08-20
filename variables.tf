variable "name" {
  description = "Name of service"
  default     = ""
}

variable "service_count" {
  description = "Number of desired task"
  default     = 1
}

variable "subnets" {
  description = "Private subnets from VPC"
  default     = []
}

variable "security_groups" {
  description = "Security groups allowed"
  default     = []
}

variable "cluster" {
  description = "Cluster used in ecs"
  default     = ""
}

variable "role_service" {
  description = "Role for execution service"
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID for create target group resources"
  default     = ""
}

variable "cpu_unit" {
  description = "Number of cpu units for container"
  default     = 256
}

variable "memory" {
  description = "Number of memory for container"
  default     = 512
}

variable "roleArn" {
  description = "Role Iam for task def"
  default     = ""
}

variable "roleExecArn" {
  description = "Role Iam for execution"
  default     = ""
}

variable "environment" {
  description = "Environment variables for ecs task"
  default     = []
}

variable "secrets_name" {
  description = "Secrets name for ecs task"
}

variable "secrets_value_arn" {
  description = "Secrets values for ecs task"
}

variable "auto_scale_role" {
  description = "IAM Role for autocaling services"
  default     = ""
}

variable "service_role_codedeploy" {
  description = "Role for ecs codedeploy"
  default     = ""
}

variable "dummy_deps" {
  description = "Dummy dependencies for interpolation step"
  default     = ""
}

variable "max_scale" {
  description = "Maximun number of task scaling"
  default     = 3
}

variable "min_scale" {
  description = "Minimun number of task scaling"
  default     = 1
}

variable "public_ip" {
  default     = false
  description = "Flag to set auto assign public ip"
}

variable "ecr_image_url" {
  description = "ECR docker image"
}

variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "database_log_level" {
  description = "Database log level"
  default     = "error"
}

variable "log_level" {
  description = "App log level"
  default     = "info"
}

variable "port" {
  description = "Port number exposed by container"
  default     = ""
}

variable "prefix_logs" {
  default = "ecs"
}

variable "es_url" {
  description = "Elasticsearch url to streaming logs"
}