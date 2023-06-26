# ------------------------------------------------------------------------------
# Document Database Context
# ------------------------------------------------------------------------------
module "ddb_context" {
  source  = "registry.terraform.io/SevenPico/context/null"
  version = "2.0.0"
  context = module.context.self
  name    = "ddb"
}

locals {
  ddb_username = "admin1"
  ddb_password = join("", random_password.ddb.*.result)

  ddb_opts = {
    replicaSet     = "rs0"
    readPreference = "secondaryPreferred"
    retryWrites    = false
  }

  ddb_opts_str = join("&", [for k, v in local.ddb_opts : "${k}=${v}"])
  ddb_url_fmt  = "mongodb://${local.ddb_username}:${local.ddb_password}@${module.ddb_context.dns_name}:${var.ddb_port}/%s?${local.ddb_opts_str}"
}


# ------------------------------------------------------------------------------
# DDB Credentials
# ------------------------------------------------------------------------------
resource "random_password" "ddb" {
  //  count   = module.ddb_context.enabled ? 1 : 0
  length  = 16
  special = false
}


# ------------------------------------------------------------------------------
# DDB
# ------------------------------------------------------------------------------
module "ddb" {
  source  = "registry.terraform.io/SevenPicoForks/documentdb-cluster/aws"
  version = "2.0.1"
  context = module.ddb_context.self

  allowed_cidr_blocks             = []
  allowed_security_groups         = concat([module.openvpn.security_group_id])
  apply_immediately               = true
  auto_minor_version_upgrade      = true
  cluster_dns_name                = ""
  cluster_family                  = "docdb4.0"
  cluster_size                    = 1
  db_port                         = var.ddb_port
  deletion_protection             = false
  enabled_cloudwatch_logs_exports = ["audit"]
  engine                          = "docdb"
  engine_version                  = ""
  instance_class                  = "db.t3.medium"
  kms_key_id                      = module.ddb_kms_key.key_arn
  master_password                 = local.ddb_password
  master_username                 = local.ddb_username
  preferred_backup_window         = "07:00-09:00"
  preferred_maintenance_window    = "Mon:22:00-Mon:23:00"
  reader_dns_name                 = ""
  retention_period                = 30
  skip_final_snapshot             = false
  snapshot_identifier             = ""
  storage_encrypted               = true
  subnet_ids                      = module.vpc_subnets.private_subnet_ids
  vpc_id                          = module.vpc.vpc_id
  zone_id                         = aws_route53_zone.private[0].zone_id
  cluster_parameters = [{
    apply_method = "pending-reboot"
    name         = "tls"
    value        = "enabled"
  }]
}


# ------------------------------------------------------------------------------
# DDB Secret
# ------------------------------------------------------------------------------
module "ddb_secret" {
  source  = "registry.terraform.io/SevenPico/secret/aws"
  version = "3.1.0"
  context = module.ddb_context.self
  enabled = module.ddb_context.enabled

  create_sns                      = false
  description                     = "DocumentDB Credentials"
  kms_key_deletion_window_in_days = 14
  kms_key_enable_key_rotation     = false
  secret_ignore_changes           = false
  secret_read_principals          = {}
  secret_string = jsonencode({
    "username"          = local.ddb_username
    "password"          = local.ddb_password
    "connection_string" = local.ddb_url_fmt
  })
  sns_pub_principals = {}
  sns_sub_principals = {}
}


# ------------------------------------------------------------------------------
# DDB KMS Key
# ------------------------------------------------------------------------------
module "ddb_kms_key" {
  source  = "SevenPicoForks/kms-key/aws"
  version = "2.0.0"
  context = module.ddb_context.self

  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days  = 14
  description              = "KMS key for ${module.ddb_context.id}"
  enable_key_rotation      = false
  key_usage                = "ENCRYPT_DECRYPT"
  multi_region             = false
  policy                   = ""
}


# ------------------------------------------------------------------------------
# DDB DNS
# ------------------------------------------------------------------------------
resource "aws_route53_record" "ddb" {
  count   = module.ddb_context.enabled ? 1 : 0
  zone_id = aws_route53_zone.private[0].zone_id
  type    = "CNAME"
  name    = module.ddb_context.dns_name
  records = [module.ddb.endpoint]
  ttl     = 300
}
