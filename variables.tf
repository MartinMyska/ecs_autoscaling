variable "project_name" {}

variable "cluster_name" {
  description = "Name of the cluster to enable autoscaling"
}

variable "service_name" {
  description = "ECS service name to enable autoscaling"
}

variable "min_capacity" {
  description = "Desired minimum capacity for autoscaling target"
}

variable "max_capacity" {
  description = "Desired maximum capacity for autoscaling target"
}

variable "scaleup_eval_period" {
  description = "Scaling UP CloudWatch alarm rule evaluation period in seconds"
}

variable "scaledn_eval_period" {
  description = "Scaling DOWN CloudWatch alarm rule evaluation period in seconds"
}

variable "scaleup_alarm_period" {
  description = "How long alarm should be firing before triggering scaling UP"
}

variable "scaledn_alarm_period" {
  description = "How long alarm should be firing before triggering scaling DOWN"
}

variable "highcpu_threshold" {
  description = "How much CPU should be loaded to trigger alarm"
}

variable "lowcpu_threshold" {
  description = "How much CPU should be loaded to trigger alarm"
}

variable "scaling_cooldown" {
  description = "How long to wait before next scaling can happen"
}
