locals {
  mandatory_tags = {
    Environment = "${var.environment}"
    CostCenter  = "${var.costcenter}"
    Owner       = "${var.owner}"
    Application = "${var.application}"
  }
}
