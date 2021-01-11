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

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }
}

// AWS ECS Task definition to run the container passed by name
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.name}-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = var.roleExecArn
  task_role_arn            = var.roleArn
  cpu                      = var.cpu_unit
  memory                   = var.memory

  container_definitions    = <<TASK_DEFINITION
[
  {
    "essential": true,
    "image": "906394416424.dkr.ecr.us-east-1.amazonaws.com/aws-for-fluent-bit:latest",
    "name": "log_router",
    "firelensConfiguration": {
      "type": "fluentbit",
      "options": {
        "config-file-type": "file",
        "config-file-value": "/fluent-bit/configs/parse-json.conf"
      }
    },
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${var.name}-firelens-container",
        "awslogs-region": "${var.region}",
        "awslogs-create-group": "true",
        "awslogs-stream-prefix": "firelens"
      }
    },
    "memoryReservation": 50
  },
  {
    "essential": true,
    "image": "${var.ecr_image_url}",
    "name": "${var.name}",
    "portMappings": [
      {
        "containerPort": ${var.port},
        "hostPort": ${var.port}
      }
    ],
    "logConfiguration": {
      "logDriver":"awsfirelens",
      "options": {
        "Name": "es",
        "Host": "${var.es_url}",
        "Port": "443",
        "Index": "${lower(var.name)}",
        "Type": "${lower(var.name)}_type",
        "Aws_Auth": "On",
        "Aws_Region": "${var.region}",
        "tls": "On"
      }
    },
    "secrets": [
      {
        "name": "${var.secrets_name}",
        "valueFrom": "${var.secrets_value_arn}"
      }
    ],
    "environment": [
      {
        "name": "DATABASE_LOG_LEVEL",
        "value": "${var.database_log_level}"
      },
      {
        "name": "APP",
        "value": "${var.name}"
      },
      {
        "name": "LOG_LEVEL",
        "value": "${var.log_level}"
      },
      {
        "name": "PORT",
        "value": "${var.port}"
      },
      {
        "name": "NEW_RELIC_APP_NAME",
        "value": "${var.name}"
      }
    ]
  }
]
TASK_DEFINITION
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

// AWS Autoscaling policy to scale using cpu allocation
resource "aws_appautoscaling_policy" "cpu" {
  name               = "ecs_scale_cpu"
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.service_namespace
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 75
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }

  depends_on = [aws_appautoscaling_target.main]

  lifecycle {
    create_before_destroy = true
  }
}

// AWS Autoscaling policy to scale using memory allocation
resource "aws_appautoscaling_policy" "memory" {
  name               = "ecs_scale_memory"
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.service_namespace
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 75
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }

  depends_on = [aws_appautoscaling_target.main]

  lifecycle {
    create_before_destroy = true
  }
}