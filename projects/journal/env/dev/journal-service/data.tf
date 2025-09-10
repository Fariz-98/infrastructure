data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket         = "dev-tf-state-bucket-matchbox3361"
    key            = "dev/vpc/terraform.tfstate"
    region         = "ap-southeast-1"
  }
}

data "terraform_remote_state" "alb" {
  backend = "s3"
  config = {
    bucket         = "dev-tf-state-bucket-matchbox3361"
    key            = "dev/alb/terraform.tfstate"
    region         = "ap-southeast-1"
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

data "terraform_remote_state" "secrets" {
  backend = "s3"
  config = {
    bucket         = "dev-tf-state-bucket-matchbox3361"
    key            = "dev/journal/secretsmanager/terraform.tfstate"
    region         = "ap-southeast-1"
  }
}

data "terraform_remote_state" "journal_iam" {
  backend = "s3"
  config = {
    bucket         = "dev-tf-state-bucket-matchbox3361"
    key            = "dev/journal/iam/terraform.tfstate"
    region         = "ap-southeast-1"
  }
}

data "terraform_remote_state" "ecs" {
  backend = "s3"
  config = {
    bucket = "dev-tf-state-bucket-matchbox3361"
    key    = "dev/ecs-cluster/terraform.tfstate"
    region = "ap-southeast-1"
  }
}