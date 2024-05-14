vpc_id                             = "vpc-01d7a2da8f9f1dfec"
environment                        = "dev"
namespace                          = "delius-core"
target_group_arn                   = "arn:aws:elasticloadbalancing:eu-west-2:326912278139:targetgroup/ldap-dev/916628de28debc57"
service_security_group_id          = "sg-0a5c692e1c206600a"
mp_subnet_prefix                   = "hmpps-development"
efs_id                             = "fs-09e171610bb5c87c4"
efs_access_point_id                = "fsap-02598b3cfe2720697"
slapd_log_level                    = "stats"
ecs_task_cpu                       = "256"
ecs_task_memory                    = "512"
ecs_desired_task_count             = 1
deployment_minimum_healthy_percent = 0
deployment_maximum_percent         = 200
