locals {
  app_name = "openldap"
}

module "container" {
  source                   = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=tags/0.60.0"
  container_name           = local.app_name
  container_image          = "374269020027.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${var.namespace}-${local.app_name}-ecr-repo:${var.image_tag}"
  container_memory         = "8192"
  container_cpu            = "4096"
  essential                = true
  readonly_root_filesystem = false
  environment = [
    {
      name  = "LDAP_HOST"
      value = "0.0.0.0"
    },
    {
      name  = "SLAPD_LOG_LEVEL"
      value = var.slapd_log_level
    },
    {
      name  = "LDAP_PORT"
      value = "389"
    }
  ]
  secrets = [
    {
      name      = "BIND_PASSWORD"
      valueFrom = data.aws_ssm_parameter.bind_password.arn
    },
    {
      name      = "MIGRATION_S3_LOCATION"
      valueFrom = data.aws_ssm_parameter.seed_uri.arn
    }
  ]
  mount_points = [{
    sourceVolume  = "delius-core-openldap"
    containerPath = "/var/lib/openldap/openldap-data"
    readOnly      = false
  }]
  port_mappings = [{
    containerPort = 389
    hostPort      = 389
    protocol      = "tcp"
  }]
  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = "/ecs/ldap_${var.environment}"
      "awslogs-region"        = data.aws_region.current.name
      "awslogs-stream-prefix" = "openldap"
    }
  }
  healthcheck = {
    command     = ["CMD-SHELL", "ldapsearch -x -H ldap://localhost:389 -b '' -s base '(objectclass=*)' namingContexts"]
    interval    = 30
    retries     = 3
    startPeriod = 60
    timeout     = 5
  }
}

module "deploy" {
  source                    = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//service?ref=c195026bcf0a1958fa4d3cc2efefc56ed876507e"
  container_definition_json = module.container.json_map_encoded_list
  ecs_cluster_arn           = "arn:aws:ecs:eu-west-2:${data.aws_caller_identity.current.id}:cluster/${var.namespace}-${var.environment}-cluster"
  name                      = local.app_name
  vpc_id                    = var.vpc_id

  launch_type  = "FARGATE"
  network_mode = "awsvpc"

  task_cpu    = var.ecs_task_cpu
  task_memory = var.ecs_task_memory

  service_role_arn   = "arn:aws:iam::${data.aws_caller_identity.current.id}:role/${var.environment}-openldap-ecs-service"
  task_role_arn      = "arn:aws:iam::${data.aws_caller_identity.current.id}:role/${var.environment}-openldap-ecs-task"
  task_exec_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.id}:role/${var.environment}-openldap-task-exec"

  environment = var.environment
  namespace   = var.namespace

  health_check_grace_period_seconds  = 60
  desired_count                      = var.ecs_desired_task_count
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent

  ecs_load_balancers = [
    {
      target_group_arn = var.target_group_arn
      container_name   = local.app_name
      container_port   = 389
    }
  ]

  security_group_ids = [var.service_security_group_id]

  subnet_ids = [
    data.aws_subnet.private_subnets_a.id,
    data.aws_subnet.private_subnets_b.id,
    data.aws_subnet.private_subnets_c.id
  ]

  efs_volumes = [
    {
      host_path = null
      name      = "delius-core-openldap"
      efs_volume_configuration = [{
        file_system_id          = var.efs_id
        root_directory          = "/"
        transit_encryption      = "ENABLED"
        transit_encryption_port = 2049
        authorization_config = [{
          access_point_id = var.efs_access_point_id
          iam             = "DISABLED"
        }]
      }]
    }
  ]

  exec_enabled = true

  ignore_changes_task_definition = false
  redeploy_on_apply              = false
  force_new_deployment           = false
}
