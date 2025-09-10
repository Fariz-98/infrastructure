data "terraform_remote_state" "state" {
  backend = "s3"
  config = {
    bucket = "dev-tf-state-bucket-matchbox3361"
    key    = "dev/terraform.tfstate"
    region = "ap-southeast-1"
  }
}

# To get account id
data "aws_caller_identity" "current" {}