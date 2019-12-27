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
  type        = "list"
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
  type        = "list"
}

variable "secrets_arn" {
  description = "Secrets arn for ecs task"
  default     = ""
  type        = string
}

variable "secrets_name" {
  description = "Secrets name for ecs task"
  default     = "Secrets"
  type        = string
}

variable "auto_scale_role" {
  description = "IAM Role for autocaling services"
  default     = ""
  type        = "string"
}

variable "service_role_codedeploy" {
  description = "Role for ecs codedeploy"
  default     = ""
  type        = "string"
}

variable "dummy_deps" {
  description = "Dummy dependencies for interpolation step"
  default     = ""
}

variable "task" {
  default     = ""
  description = "ARN of task created"
}

variable "max_scale" {
  description = "Maximun number of task scaling"
  default     = 3
}

variable "min_scale" {
  description = "Minimun number of task scaling"
  default     = 1
}

variable "lambda_stream_arn" {
  description = "ARN of function lambda to stream logs into elasticsearch"
  default     = ""
}

variable "cwl_endpoint" {
  type        = "string"
  default     = "logs.us-east-2.amazonaws.com"
  description = "Cloudwatch endpoint logs"
}

variable "public_ip" {
  default     = false
  description = "Flag to set auto assign public ip"
}

variable "disable_log_streaming" {
  default     = false
  description = "Flag todisable log streaming to kibana"
}

variable "kms_key_logs" {
  description = "KMS Key for encryption logs"
}
