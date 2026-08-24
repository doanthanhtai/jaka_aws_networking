########################
# General
########################

variable "project" {
  description = "Project name"
  type        = string
  default     = "vpc-lab"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

########################
# Networking
########################

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "private_subnet_1_cidr" {
  type    = string
  default = "10.0.11.0/24"
}

variable "private_subnet_2_cidr" {
  type    = string
  default = "10.0.12.0/24"
}

########################
# Availability Zones
########################

variable "az1" {
  type    = string
  default = "us-east-1a"
}

variable "az2" {
  type    = string
  default = "us-east-1b"
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to SSH into EC2"
  type        = string
  default     = "0.0.0.0/0"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

########################
# ECR / container images
########################

variable "order_ecr_repo_name" {
  description = "ECR repository name for the order-service image"
  type        = string
  default     = "order-service"
}

variable "payment_ecr_repo_name" {
  description = "ECR repository name for the payment-service image"
  type        = string
  default     = "payment-service"
}

variable "image_tag" {
  description = "Image tag to deploy for order-service and payment-service"
  type        = string
  default     = "latest"
}

########################
# Auto Scaling
########################

variable "asg_min_size" {
  description = "Minimum size for the order/payment Auto Scaling Groups"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum size for the order/payment Auto Scaling Groups"
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "Desired capacity for the order/payment Auto Scaling Groups"
  type        = number
  default     = 2
}

variable "rds_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "rds_allocated_storage" {
  type    = number
  default = 20
}

variable "postgres_engine_version" {
  type    = string
  default = "16"
}
