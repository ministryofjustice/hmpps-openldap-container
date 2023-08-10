output "ecs_cluster_arn" {
  value = var.cluster_arn
}

output "ecs_service_arn" {
  value = module.deploy.service_arn
}
