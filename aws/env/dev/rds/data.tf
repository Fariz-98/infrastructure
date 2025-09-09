# VPC Outputs
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "dev-tf-state-bucket-matchbox3361"
    key    = "dev/vpc/terraform.tfstate"
    region = "ap-southeast-1"
  }
}

data "terraform_remote_state" "app_sg_id" {
  backend = "s3"
  config = {
    bucket         = "dev-tf-state-bucket-matchbox3361"
    key            = "dev/journal-service/terraform.tfstate"
    region         = "ap-southeast-1"
  }
}