resource "aws_appautoscaling_target" "ecs_target" {
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "up" {
  name               = "${var.project_name}-scale-up"
  policy_type        = "StepScaling"
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
  name               = "${var.project_name}-scale-down"
  policy_type        = "StepScaling"
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
  alarm_name          = "${var.project_name}-highload"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.scaleup_eval_period
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.scaleup_alarm_period
  statistic           = "Average"
  threshold           = var.highcpu_threshold
  actions_enabled     = true
  alarm_description   = "This alarm triggers specified ECS service to scale UP based on CPU utilization"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

  alarm_actions = [aws_appautoscaling_policy.up.arn]
}

resource "aws_cloudwatch_metric_alarm" "ecs_scaledn" {
  alarm_name          = "${var.project_name}-lowload"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.scaledn_eval_period
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.scaledn_alarm_period
  statistic           = "Average"
  threshold           = var.lowcpu_threshold
  actions_enabled     = true
  alarm_description   = "This alarm triggers specified ECS service to scale DOWN based on CPU utilization"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

  alarm_actions = [aws_appautoscaling_policy.dn.arn]
}
