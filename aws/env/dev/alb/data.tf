data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket         = "dev-tf-state-bucket-matchbox3361"
    key            = "dev/vpc/terraform.tfstate"
    region         = "ap-southeast-1"
  }
}