variable "aws_region" {
  description = "AWS region where resources will be deployed"
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "The AWS account ID where resources are deployed"
  type        = string
}

variable "vpc_id" {
  description = "vpc-00cca0426394bdde3"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

#variable "ecr_repository_name" {
  #description = "Name of the ECR repository"
  #default     = "ilanas-flask-api"
#}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for static content"
  default     = "terraform-state-ilanas"
}

variable "app_port" {
  description = "Port where the application will run"
  default     = 5000
}
