variable "aws_region" { default = "ap-southeast-1" }
variable "project_name" { default = "auto-deployment-jenkins" }
variable "container_port" { default = 5000 }
variable "cpu_units" { default = "256" }
variable "memory_units" { default = "512" }
variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "public_subnet_cidr" { default = "10.0.1.0/24" }
variable "image_tag" {
  description = "The docker image tag (usually git commit hash) passed from Jenkins"
  type        = string
  default     = "latest"
}

variable "availability_zone" {
  description = "AWS Availability Zone for public subnet"
  type        = string
  default     = "ap-southeast-1a"
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "ecs_desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 1
}
