provider "aws" {
  region = "${var.region}"
}

data "aws_caller_identity" "current" {}

terraform {
  backend "s3" {
    bucket = "adikts-tfstates-bucket"
    key    = "projects/ecs_codedeploy.tfstate"
    region = "eu-west-1"
  }
}

data "terraform_remote_state" "foundation" {
  backend = "s3"

  config {
    bucket = "${var.tfstate_bucket}"
    key    = "${var.foundation_tfstate_key}"
    region = "${var.region}"
  }
}
