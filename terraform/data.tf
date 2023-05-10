data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_subnet" "private_subnets_a" {
  vpc_id = var.vpc_id
  tags = {
    "Name" = "hmpps-${var.environment}-general-private-${data.aws_region.current.name}a"
  }
}

data "aws_subnet" "private_subnets_b" {
  vpc_id = var.vpc_id
  tags = {
    "Name" = "hmpps-${var.environment}-general-private-${data.aws_region.current.name}b"
  }
}

data "aws_subnet" "private_subnets_c" {
  vpc_id = var.vpc_id
  tags = {
    "Name" = "hmpps-${var.environment}-general-private-${data.aws_region.current.name}c"
  }
}

# data "aws_lb_target_group" "service" {
#   name = var.target_group_name
# }


data "aws_secretsmanager_secret" "bind_password" {
  name = "${local.app_name}-openldap-bind-password"
}

data "aws_efs_file_system" "openldap" {
  tags = {
    Name = "${local.app_name}"
  }
}
