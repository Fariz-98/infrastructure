data "terraform_remote_state" "secretsmanager" {
  backend = "s3"
  config = {
    bucket = "dev-tf-state-bucket-matchbox3361"
    key    = "dev/secretsmanager/terraform.tfstate"
    region = "ap-southeast-1"
  }
}