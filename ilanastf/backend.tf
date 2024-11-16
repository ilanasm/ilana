terraform {
  backend "s3" {
    bucket         = "terraform-state-ilanas"
    key            = "ecs-deployment/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}
