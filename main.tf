//  AWS ECS Service to run the task definition
resource "aws_ecs_service" "main" {
  name                               = var.name
  cluster                            = var.cluster
  task_definition                    = var.task
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  desired_count                      = var.service_count
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  network_configuration {
    security_groups  = var.security_groups
    subnets          = var.subnets
    assign_public_ip = var.public_ip
  }

  lifecycle {
    create_before_destroy = true

    ignore_changes = [
      "desired_count",
    ]
  }
}

// CloudWatch logs to stream all module
resource "aws_cloudwatch_log_group" "main" {
  name              = var.name
  retention_in_days = 14
  kms_key_id        = var.kms_key_logs
}

// Streaming logs to Elasticsearch
resource "aws_lambda_permission" "main" {
  count         = var.disable_log_streaming ? 0 : 1
  statement_id  = "${var.name}_cloudwatch_allow"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_stream_arn
  principal     = var.cwl_endpoint
  source_arn    = aws_cloudwatch_log_group.main.arn
}

// Add subscription resource to streaming logs of module to Elasticsearch
resource "aws_cloudwatch_log_subscription_filter" "main" {
  count           = var.disable_log_streaming ? 0 : 1
  depends_on      = ["aws_lambda_permission.main"]
  name            = "cloudwatch_${var.name}_logs_to_elasticsearch"
  log_group_name  = aws_cloudwatch_log_group.main.name
  filter_pattern  = ""
  destination_arn = var.lambda_stream_arn

  lifecycle {
    ignore_changes = [
      "distribution",
    ]
  }
}

/*===========================================
              Autoscaling zone
============================================*/

// AWS Autoscaling target to linked the ecs cluster and service
resource "aws_appautoscaling_target" "main" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = var.auto_scale_role
  min_capacity       = var.min_scale
  max_capacity       = var.max_scale

  lifecycle {
    create_before_destroy = true

    ignore_changes = [
      "role_arn",
    ]
  }
}

// AWS Autoscaling policy to scale with additional instance if the criteria is reached
resource "aws_appautoscaling_policy" "up" {
  name               = "ecs_scale_up"
  policy_type        = "StepScaling"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      metric_interval_upper_bound = 15
      scaling_adjustment          = 1
    }

    step_adjustment {
      metric_interval_lower_bound = 15
      metric_interval_upper_bound = 25
      scaling_adjustment          = 2
    }

    step_adjustment {
      metric_interval_lower_bound = 25
      scaling_adjustment          = 3
    }
  }

  depends_on = ["aws_appautoscaling_target.main"]

  lifecycle {
    create_before_destroy = true
  }
}

// AWS Autoscaling policy to scale down instance if the criteria is reached
resource "aws_appautoscaling_policy" "down" {
  name               = "ecs_scale_down"
  policy_type        = "StepScaling"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = ["aws_appautoscaling_target.main"]

  lifecycle {
    create_before_destroy = true
  }
}

// Metric used for auto scale to detect if the cpu consuming is high
resource "aws_cloudwatch_metric_alarm" "service_cpu_high" {
  alarm_name          = "cpu_utilization_high_${var.name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    ClusterName = var.cluster
    ServiceName = aws_ecs_service.main.name
  }

  alarm_actions = [aws_appautoscaling_policy.up.arn]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "service_cpu_low" {
  alarm_name          = "cpu_utilization_low_${var.name}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "20"

  dimensions = {
    ClusterName = var.cluster
    ServiceName = aws_ecs_service.main.name
  }

  alarm_actions = [aws_appautoscaling_policy.down.arn]

  lifecycle {
    create_before_destroy = true
  }
}
