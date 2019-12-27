output "ecs_service_id" {
  description = "ID of service created"
  value       = aws_ecs_service.main.id
}
