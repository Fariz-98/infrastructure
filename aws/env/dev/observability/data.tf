data "terraform_remote_state" "rds" {
  backend = "s3"
  config = {
    bucket         = "dev-tf-state-bucket-matchbox3361"
    key            = "dev/rds/terraform.tfstate"
    region         = "ap-southeast-1"
  }
}