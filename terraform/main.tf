locals {
  app_name = "delius-core-openldap"
}

module "container" {
  source                   = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=tags/0.58.1"
  container_name           = local.app_name
  container_image          = "374269020027.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${local.app_name}-ecr-repo:${var.image_tag}"
  container_memory         = "2048"
  container_cpu            = "1024"
  essential                = true
  readonly_root_filesystem = false
  environment = [
    {
      name  = "LDAP_HOST"
      value = "0.0.0.0"
    },
    {
      name  = "SLAPD_LOG_LEVEL"
      value = "trace"
    },
    {
      name  = "LDAP_PORT"
      value = "3890"
    }
  ]
  port_mappings = [{
    containerPort = 389
    hostPort      = 389
    protocol      = "tcp"
  }]
  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = "${local.app_name}-ecs"
      "awslogs-region"        = data.aws_region.current.name
      "awslogs-stream-prefix" = "openldap"
    }
  }
}

module "deploy" {
  source                    = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//service?ref=423c0f493e9af0e1260caa1ee65bac7f8fd95e12"
  container_definition_json = module.container.json_map_encoded_list
  ecs_cluster_arn           = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/hmpps-${var.environment}-${local.app_name}"
  name                      = local.app_name
  vpc_id                    = var.vpc_id

  launch_type  = "FARGATE"
  network_mode = "awsvpc"

  task_cpu    = "1024"
  task_memory = "4096"

  service_role_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/hmpps-${var.environment}-${local.app_name}-service"
  task_role_arn      = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/hmpps-${var.environment}-${local.app_name}-task"
  task_exec_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/hmpps-${var.environment}-${local.app_name}-task-exec"

  task_exec_policy_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/jitbit-secrets-reader"]

  environment = var.environment

  # ecs_load_balancers = [
  #   {
  #     target_group_arn = data.aws_lb_target_group.service.arn
  #     container_name   = local.app_name
  #     container_port   = 5000
  #   }
  # ]

  security_group_ids = [var.service_security_group_id]

  subnet_ids = [
    data.aws_subnet.private_subnets_a.id,
    data.aws_subnet.private_subnets_b.id,
    data.aws_subnet.private_subnets_c.id
  ]

  ignore_changes_task_definition = false
  redeploy_on_apply              = false
  force_new_deployment           = false
}
