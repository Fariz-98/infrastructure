terraform {
  backend "s3" {
    bucket         = "dev-tf-state-bucket-matchbox3361"
    key            = "dev/observability/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "dev-tf-state-lock"
    encrypt        = true
  }
}