data "terraform_remote_state" "secretsmanager" {
  backend = "s3"
  config = {
    bucket = "dev-tf-state-bucket-matchbox3361"
    key    = "dev/secretsmanager/terraform.tfstate"
    region = "ap-southeast-1"
  }
}

data "terraform_remote_state" "rds" {
  backend = "s3"
  config = {
    bucket         = "dev-tf-state-bucket-matchbox3361"
    key            = "dev/rds/terraform.tfstate"
    region         = "ap-southeast-1"
  }
}

# To create github oicd role
data "aws_caller_identity" "current" {}

data "terraform_remote_state" "ecr" {
  backend = "s3"
  config = {
    bucket = "dev-tf-state-bucket-matchbox3361"
    key    = "dev/journal/ecr/terraform.tfstate"
    region = "ap-southeast-1"
  }
}