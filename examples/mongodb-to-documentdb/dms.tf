locals {
  enabled              = module.context.enabled
  vpc_id               = module.vpc.vpc_id
  vpc_cidr_block       = module.vpc.vpc_cidr_block
  subnet_ids           = module.vpc_subnets.private_subnet_ids
  route_table_ids      = module.vpc_subnets.private_route_table_ids
  security_group_id    = module.security_group.id
  create_dms_iam_roles = local.enabled && var.create_dms_iam_roles
}

# Database Migration Service requires
# the below IAM Roles to be created before
# replication instances can be created.
# The roles should be provisioned only once per account.
# https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.html
# https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.html#CHAP_Security.APIRole
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dms_replication_instance
#  * dms-vpc-role
#  * dms-cloudwatch-logs-role
#  * dms-access-for-endpoint
module "dms_iam" {
  source = "../../modules/dms-iam"

  enabled = local.create_dms_iam_roles

  context = module.context.self
}

module "dms_replication_instance" {
  source = "../../modules/dms-replication-instance"

  # https://docs.aws.amazon.com/dms/latest/userguide/CHAP_ReleaseNotes.html
  engine_version             = "3.4.6"
  replication_instance_class = "dms.t2.small"


  allocated_storage            = 50
  apply_immediately            = true
  auto_minor_version_upgrade   = true
  allow_major_version_upgrade  = false
  multi_az                     = false
  publicly_accessible          = false
  preferred_maintenance_window = "sun:10:30-sun:14:30"
  vpc_security_group_ids       = [
    local.security_group_id, module.ddb.security_group_id, module.openvpn.security_group_id
  ]
  subnet_ids                   = local.subnet_ids

  context = module.context.self

  depends_on = [
    # The required DMS roles must be present before replication instances can be provisioned
    module.dms_iam
  ]
}

module "dms_endpoint_mongodb" {
  source     = "../../modules/dms-endpoint"
  context    = module.context.self
  attributes = ["source"]

  endpoint_type    = "source"
  engine_name      = "mongodb"
  mongodb_settings = {
    auth_mechanism      = "scram-sha-1"
    //(Optional) Authentication mechanism to access the MongoDB source endpoint. Defaults to default
    auth_source         = "admin"
    //(Optional) Authentication database name. Not used when auth_type is no. Defaults to admin.
    auth_type           = "password"
    //(Optional) Authentication type to access the MongoDB source endpoint. Defaults to password.
    docs_to_investigate = 1000
    //(Optional) Number of documents to preview to determine the document organization. Use this setting when nesting_level is set to one. Defaults to 1000
    extract_doc_id      = false
    //(Optional) Document ID. Use this setting when nesting_level is set to none. Defaults to false.
    nesting_level       = "none" //Valid values are one (table mode) and none (document mode).
  }


  server_name                     = var.mongodb_server
  database_name                   = var.mongodb_database_name
  port                            = var.mongodb_port
  username                        = var.mongodb_user
  password                        = var.mongodb_password
  extra_connection_attributes     = ""
  secrets_manager_access_role_arn = null
  secrets_manager_arn             = null
  ssl_mode                        = "require"

  #  certificate_arn = ""
  #  kms_key_arn = ""

}

resource "aws_dms_certificate" "ddb" {
  count = module.context.enabled ? 1 : 0
  certificate_pem = one(data.external.rds_combined_ca_bundle[*].result.bundle)
  certificate_id  = module.context.id
}

module "dms_endpoint_documentdb" {
  source     = "../../modules/dms-endpoint"
  context    = module.context.self
  attributes = ["target"]

  endpoint_type = "target"
  engine_name   = "docdb"
  #  docdb_settings = {
  #    auth_mechanism      = "default" //(Optional) Authentication mechanism to access the MongoDB source endpoint. Defaults to default
  #    auth_source         = "admin" //(Optional) Authentication database name. Not used when auth_type is no. Defaults to admin.
  #    auth_type           = "password" //(Optional) Authentication type to access the MongoDB source endpoint. Defaults to password.
  #    docs_to_investigate = 1000 //(Optional) Number of documents to preview to determine the document organization. Use this setting when nesting_level is set to one. Defaults to 1000
  #    extract_doc_id      =  false //(Optional) Document ID. Use this setting when nesting_level is set to none. Defaults to false.
  #    nesting_level       = "none" //Valid values are one (table mode) and none (document mode).
  #  }

  server_name                     = module.ddb.endpoint
  database_name                   = module.ddb.cluster_name
  port                            = var.ddb_port
  username                        = local.ddb_username
  password                        = local.ddb_password
  extra_connection_attributes     = ""
  secrets_manager_access_role_arn = null
  secrets_manager_arn             = null
  ssl_mode                        = "verify-full"
  certificate_arn                 = try(aws_dms_certificate.ddb[0].certificate_arn, "")

  depends_on = [
    module.ddb
  ]
}

resource "time_sleep" "wait_for_dms_endpoints" {
  count = local.enabled ? 1 : 0

  depends_on = [
    module.dms_endpoint_mongodb,
    module.dms_endpoint_documentdb
  ]

  create_duration  = "2m"
  destroy_duration = "30s"
}

# `dms_replication_task` will be created (at least) 2 minutes after `dms_endpoint_aurora_postgres` and `dms_endpoint_s3_bucket`
# `dms_endpoint_aurora_postgres` and `dms_endpoint_s3_bucket` will be destroyed (at least) 30 seconds after `dms_replication_task`
module "dms_replication_task" {
  source = "../../modules/dms-replication-task"

  replication_instance_arn = module.dms_replication_instance.replication_instance_arn
  start_replication_task   = true
  migration_type           = "full-load-and-cdc"
  source_endpoint_arn      = module.dms_endpoint_mongodb.endpoint_arn
  target_endpoint_arn      = module.dms_endpoint_documentdb.endpoint_arn

  # https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.CustomizingTasks.TaskSettings.html
  replication_task_settings = file("${path.module}/config/replication-task-settings.json")

  # https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.CustomizingTasks.TableMapping.html
  table_mappings = file("${path.module}/config/replication-task-table-mappings.json")

  context = module.context.self

  depends_on = [
    module.dms_endpoint_documentdb,
    module.dms_endpoint_mongodb,
    time_sleep.wait_for_dms_endpoints
  ]
}

module "dms_replication_instance_event_subscription" {
  source = "../../modules/dms-event-subscription"

  event_subscription_enabled = true
  source_type                = "replication-instance"
  source_ids                 = [module.dms_replication_instance.replication_instance_id]
  sns_topic_arn              = module.sns_topic.sns_topic_arn

  # https://awscli.amazonaws.com/v2/documentation/api/latest/reference/dms/describe-event-categories.html
  event_categories = [
    "low storage",
    "configuration change",
    "maintenance",
    "deletion",
    "creation",
    "failover",
    "failure"
  ]

  attributes = ["instance"]
  context    = module.context.self
}

module "dms_replication_task_event_subscription" {
  source = "../../modules/dms-event-subscription"

  event_subscription_enabled = true
  source_type                = "replication-task"
  source_ids                 = [module.dms_replication_task.replication_task_id]
  sns_topic_arn              = module.sns_topic.sns_topic_arn

  # https://awscli.amazonaws.com/v2/documentation/api/latest/reference/dms/describe-event-categories.html
  event_categories = [
    "configuration change",
    "state change",
    "deletion",
    "creation",
    "failure"
  ]

  attributes = ["task"]
  context    = module.context.self
}
