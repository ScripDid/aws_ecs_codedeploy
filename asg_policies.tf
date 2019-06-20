resource "aws_autoscaling_policy" "memory_out_autoscaling_policy" {
  name                   = "asp-${var.owner}-${var.application}_memory_scale_out_policy"
  scaling_adjustment     = "${var.scaling_adjustment}"
  adjustment_type        = "ChangeInCapacity"
  cooldown               = "${var.cooldown_duration}"
  autoscaling_group_name = "${aws_cloudformation_stack.asg_cloudformation_stack.outputs["asgName"]}"
}

resource "aws_autoscaling_policy" "cpu_out_autoscaling_policy" {
  name                   = "asp-${var.owner}-${var.application}_cpu_scale_out_policy"
  scaling_adjustment     = "${var.scaling_adjustment}"
  adjustment_type        = "ChangeInCapacity"
  cooldown               = "${var.cooldown_duration}"
  autoscaling_group_name = "${aws_cloudformation_stack.asg_cloudformation_stack.outputs["asgName"]}"
}

resource "aws_autoscaling_policy" "cpu_mem_in_autoscaling_policy" {
  name                   = "asp-${var.owner}-${var.application}_cpu_and_mem_scale_in_policy"
  scaling_adjustment     = "-${var.scaling_adjustment}"
  adjustment_type        = "ChangeInCapacity"
  cooldown               = "${var.cooldown_duration}"
  autoscaling_group_name = "${aws_cloudformation_stack.asg_cloudformation_stack.outputs["asgName"]}"
}
