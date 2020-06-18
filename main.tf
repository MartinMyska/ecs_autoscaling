locals {
  project_id = "${var.project_name}-${var.environment}"
}

resource "aws_appautoscaling_target" "ecs_target" {
  min_capacity = var.min_capacity
  max_capacity = var.max_capacity
  # resourceId accotding to AWS API docs
  # https://docs.aws.amazon.com/autoscaling/application/APIReference/app-as-api.pdf#%5B%7B%22num%22%3A1254%2C%22gen%22%3A0%7D%2C%7B%22name%22%3A%22XYZ%22%7D%2C72%2C712.8%2Cnull%5D
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount" # this string consists of the service namespace, resource type, and scalingproperty.
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "up" {
  name               = "${local.project_id}_scale_up"
  policy_type        = "StepScaling" # StepScaling is default, other possible value is TargetTrackingScaling
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.scaling_cooldown
    metric_aggregation_type = "Average"
    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
  depends_on = [aws_appautoscaling_target.ecs_target]
}

resource "aws_appautoscaling_policy" "dn" {
  name               = "${local.project_id}_scale_down"
  policy_type        = "StepScaling" # StepScaling is default, other possible value is TargetTrackingScaling
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.scaling_cooldown
    metric_aggregation_type = "Average"
    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
  depends_on = [aws_appautoscaling_target.ecs_target]
}

resource "aws_cloudwatch_metric_alarm" "ecs_scaleup" {
  alarm_name          = "${local.project_id}_${var.service_name}_highload"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.scaleup_eval_period
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.scaleup_alarm_period
  statistic           = "Average"
  threshold           = var.highcpu_threshold
  actions_enabled     = true # Indicates whether or not actions should be executed during any changes to the alarm's state. 
  alarm_description   = "This alarm triggers specified ECS service to scale UP based on CPU utilization"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

  alarm_actions = [aws_appautoscaling_policy.up.arn]
}

resource "aws_cloudwatch_metric_alarm" "ecs_scaledn" {
  alarm_name          = "${local.project_id}_${var.service_name}_lowload"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.scaledn_eval_period
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.scaledn_alarm_period
  statistic           = "Average"
  threshold           = var.lowcpu_threshold
  actions_enabled     = true # Indicates whether or not actions should be executed during any changes to the alarm's state. 
  alarm_description   = "This alarm triggers specified ECS service to scale DOWN based on CPU utilization"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

  alarm_actions = [aws_appautoscaling_policy.dn.arn]
}
