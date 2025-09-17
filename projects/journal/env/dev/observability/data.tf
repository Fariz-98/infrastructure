data "terraform_remote_state" "alerts" {
  backend = "s3"
  config = {
    bucket         = "dev-tf-state-bucket-matchbox3361"
    key            = "dev/observability/terraform.tfstate"
    region         = "ap-southeast-1"
  }
}

data "terraform_remote_state" "journal_service" {
  backend = "s3"
  config = {
    bucket         = "dev-tf-state-bucket-matchbox3361"
    key            = "dev/journal-service/terraform.tfstate"
    region         = "ap-southeast-1"
  }
}

data "terraform_remote_state" "ecs_cluster" {
  backend = "s3"
  config = {
    bucket         = "dev-tf-state-bucket-matchbox3361"
    key            = "dev/ecs-cluster/terraform.tfstate"
    region         = "ap-southeast-1"
  }
}