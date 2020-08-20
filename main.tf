/*
@doc()
# Service without traffic control ecs documentation
Module to provisioning services and rolling update deployments and autoscaling ecs task with cloudwatch alarms
*/

//  AWS ECS Service to run the task definition
resource "aws_ecs_service" "main" {
  name                               = var.name
  cluster                            = var.cluster
  task_definition                    = aws_ecs_task_definition.main.arn
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  desired_count                      = var.service_count
  force_new_deployment               = true
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
      desired_count,
    ]
  }
}

// AWS ECS Task defintion to run the container passed by name
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.name}-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = var.roleExecArn
  task_role_arn            = var.roleArn
  cpu                      = var.cpu_unit
  memory                   = var.memory
  container_definitions    = data.template_file.main.rendered
}

data "template_file" "main" {
  template = file("${path.module}/task_definition.json")

  vars = {
    ecr_image_url      = var.ecr_image_url
    name               = var.name
    port               = var.port
    region             = var.region
    secrets_name       = var.secrets_name
    secrets_value_arn  = var.secrets_value_arn
    database_log_level = var.database_log_level
    log_level          = var.log_level
    prefix_logs        = var.prefix_logs
    es_url             = var.es_url
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
      role_arn,
    ]
  }
}

// AWS Autoscaling policy to scale with additional instance if the criteria is reached
resource "aws_appautoscaling_policy" "up" {
  name               = "ecs_scale_up"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.main]

  lifecycle {
    create_before_destroy = true
  }
}

// AWS Autoscaling policy to scale down instance if the criteria is reached
resource "aws_appautoscaling_policy" "down" {
  name               = "ecs_scale_down"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.main]

  lifecycle {
    create_before_destroy = true
  }
}