locals {
  app_name = "delius-core-openldap"
}

module "container_test" {
  source                   = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=tags/0.59.0"
  container_name           = local.app_name
  container_image          = "374269020027.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${local.app_name}-ecr-repo:ldap_test"
  container_memory         = "2048"
  container_cpu            = "1024"
  essential                = true
  readonly_root_filesystem = false
  environment = [
    {
      name  = "LDAP_SERVER"
      value = "delius-core-openldap-nlb-031548f823b8589d.elb.eu-west-2.amazonaws.com"
    }
  ]
  secrets = [
    {
      name      = "BIND_PASSWORD"
      valueFrom = data.aws_secretsmanager_secret.bind_password.arn
    }
  ]
  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = "${local.app_name}-ecs-ldap-test"
      "awslogs-region"        = data.aws_region.current.name
      "awslogs-stream-prefix" = "openldap-test"
    }
  }
}

module "deploy_test" {
  source                    = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//service?ref=5f488ac0de669f53e8283fff5bcedf5635034fe1"
  container_definition_json = module.container_test.json_map_encoded_list
  ecs_cluster_arn           = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/hmpps-${var.environment}-${local.app_name}"
  name                      = ldap_test
  vpc_id                    = var.vpc_id

  launch_type  = "FARGATE"
  network_mode = "awsvpc"

  task_cpu    = "1024"
  task_memory = "2048"

  service_role_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/hmpps-${var.environment}-${local.app_name}-service"
  task_role_arn      = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/hmpps-${var.environment}-${local.app_name}-task"
  task_exec_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/hmpps-${var.environment}-${local.app_name}-task-exec"

  task_exec_policy_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/jitbit-secrets-reader"]

  environment = var.environment

  security_group_ids = [var.service_security_group_id]

  subnet_ids = [
    data.aws_subnet.private_subnets_a.id,
    data.aws_subnet.private_subnets_b.id,
    data.aws_subnet.private_subnets_c.id
  ]

  exec_enabled = true

  ignore_changes_task_definition = false
  redeploy_on_apply              = false
  force_new_deployment           = false
}
