locals {
  app_name = "openldap"
}

# module "container" {
#   source                   = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//container?ref=v4.3.0"
#   name                     = local.app_name
#   image                    = "374269020027.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${var.namespace}-${local.app_name}-ecr-repo:${var.image_tag}"
#   essential                = true
#   readonly_root_filesystem = false
#   environment = [
#     {
#       name  = "LDAP_HOST"
#       value = "0.0.0.0"
#     },
#     {
#       name  = "SLAPD_LOG_LEVEL"
#       value = var.slapd_log_level
#     },
#     {
#       name  = "LDAP_PORT"
#       value = "389"
#     },
#     {
#       name  = "DELIUS_ENVIRONMENT"
#       value = "${var.namespace}-${var.environment}"
#     }
#   ]
#   secrets = [
#     {
#       name      = "BIND_PASSWORD"
#       valueFrom = data.aws_ssm_parameter.bind_password.arn
#     },
#     {
#       name      = "MIGRATION_S3_LOCATION"
#       valueFrom = data.aws_ssm_parameter.seed_uri.arn
#     },
#     {
#       name      = "RBAC_TAG"
#       valueFrom = data.aws_ssm_parameter.ldap_rbac_version.arn
#     }
#   ]
#   mount_points = [{
#     sourceVolume  = "delius-core-openldap"
#     containerPath = "/var/lib/openldap/openldap-data"
#     readOnly      = false
#   }]
#   port_mappings = [{
#     containerPort = 389
#     hostPort      = 389
#     protocol      = "tcp"
#   }]
#   log_configuration = {
#     logDriver = "awslogs"
#     options = {
#       "awslogs-group"         = "/ecs/ldap-${var.environment}"
#       "awslogs-region"        = data.aws_region.current.name
#       "awslogs-stream-prefix" = "openldap"
#     }
#   }
#   health_check = {
#     command     = ["CMD-SHELL", "ldapsearch -x -H ldap://localhost:389 -b '' -s base '(objectclass=*)' namingContexts"]
#     interval    = 30
#     retries     = 3
#     startPeriod = 60
#     timeout     = 5
#   }

#   system_controls = [
#     {
#       namespace = "net.ipv4.tcp_keepalive_time"
#       value     = "300"
#     }
#   ]
# }

# module "deploy" {
#   source                = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//service?ref=v4.3.0"
#   container_definitions = module.container.json_encoded_list
#   cluster_arn           = "arn:aws:ecs:eu-west-2:${data.aws_caller_identity.current.id}:cluster/${var.namespace}-${var.environment}-cluster"
#   name                  = local.app_name

#   task_cpu    = var.ecs_task_cpu
#   task_memory = var.ecs_task_memory

#   service_role_arn   = "arn:aws:iam::${data.aws_caller_identity.current.id}:role/${var.environment}-ldap-ecs-service"
#   task_role_arn      = "arn:aws:iam::${data.aws_caller_identity.current.id}:role/${var.environment}-ldap-ecs-task"
#   task_exec_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.id}:role/${var.environment}-ldap-ecs-task-exec"

#   health_check_grace_period_seconds  = 60
#   desired_count                      = var.ecs_desired_task_count
#   deployment_maximum_percent         = var.deployment_maximum_percent
#   deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent

#   service_load_balancers = [
#     {
#       target_group_arn = var.target_group_arn
#       container_name   = local.app_name
#       container_port   = 389
#     }
#   ]

#   security_groups = [var.service_security_group_id]

#   subnets = [
#     data.aws_subnet.private_subnets_a.id,
#     data.aws_subnet.private_subnets_b.id,
#     data.aws_subnet.private_subnets_c.id
#   ]

#   efs_volumes = [
#     {
#       host_path = null
#       name      = "delius-core-openldap"
#       efs_volume_configuration = [{
#         file_system_id          = var.efs_id
#         root_directory          = "/"
#         transit_encryption      = "ENABLED"
#         transit_encryption_port = 2049
#         authorization_config = [{
#           access_point_id = var.efs_access_point_id
#           iam             = "DISABLED"
#         }]
#       }]
#     }
#   ]

#   enable_execute_command = true

#   ignore_changes       = false
#   force_new_deployment = false
# }
