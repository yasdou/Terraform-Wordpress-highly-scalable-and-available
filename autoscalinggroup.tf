resource "aws_autoscaling_group" "WPautoscaling" {
  min_size             = 2
  max_size             = 6
  desired_capacity     = 2
  launch_template {
    id = aws_launch_template.launchtemplate.id
  }
  vpc_zone_identifier  = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  target_group_arns    = [aws_alb_target_group.WPTG.arn]
}