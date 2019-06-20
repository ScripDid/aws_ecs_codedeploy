locals {
  mandatory_tags = {
    # Application = "${var.application}"
    # Environment = "${var.environment}"
    DeploymentType = "Deployed using Terraform"

    Owner     = "${var.owner}"
    CreatedBy = "${var.operator}"
  }
}
