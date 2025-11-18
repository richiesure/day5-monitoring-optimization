# variables.tf - Input variables for monitoring infrastructure

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
  default     = "richieprograms@gmail.com"
}

variable "ec2_instance_id" {
  description = "EC2 instance ID to monitor"
  type        = string
  default     = "i-077464828f9d99024"
}

variable "lambda_function_name" {
  description = "Lambda function name to monitor"
  type        = string
  default     = "ec2-automated-backup"
}

variable "ecs_cluster_name" {
  description = "ECS cluster name to monitor"
  type        = string
  default     = "devops-day3-cluster"
}

variable "ecs_service_name" {
  description = "ECS service name to monitor"
  type        = string
  default     = "devops-day3-service"
}

variable "cost_alert_threshold" {
  description = "Monthly cost alert threshold in USD"
  type        = number
  default     = 50
}
