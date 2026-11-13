
variable "aws_region" {
  description = "AWS region for the project"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used for resource tagging"
  type        = string
  default     = "ec2-automated-monitoring"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "EC2 root EBS volume size in GB"
  type        = number
  default     = 8
}

variable "alert_email" {
  description = "Email address that receives CloudWatch alerts"
  type        = string
}