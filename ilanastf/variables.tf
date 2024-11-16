variable "aws_region" {
  description = "AWS region where resources will be deployed"
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "821594384510"
  type        = string
}

variable "vpc_id" {
  description = "vpc-00cca0426394bdde3"
  type        = string
}

variable "public_subnets" {
  description = ["subnet-010984fc584567991" ,"subnet-053dd78d5c5a4253a"]
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
