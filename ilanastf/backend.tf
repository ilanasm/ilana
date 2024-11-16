terraform {
  backend "s3" {
    bucket         = "terraform-state-ilanas"
    key            = "ecs-deployment/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}
