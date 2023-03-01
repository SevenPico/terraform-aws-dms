# ------------------------------------------------------------------------------
# SSL Certificate
# ------------------------------------------------------------------------------
module "ssl_certificate" {
  source     = "registry.terraform.io/SevenPico/ssl-certificate/aws"
  version    = "8.0.1"
  context    = module.context.self
  attributes = ["ssl-certificate"]
  depends_on = [
    aws_route53_zone.public
  ]

  additional_dns_names              = []
  additional_secrets = {
    RDS_COMBINED_CA_BUNDLE = one(data.external.rds_combined_ca_bundle[*].result.bundle)
  }
  create_mode                       = "LetsEncrypt"
  create_secret_update_sns          = false
  create_wildcard                   = true
  import_filepath_certificate       = null
  import_filepath_certificate_chain = null
  import_filepath_private_key       = null
  import_secret_arn                 = null
  keyname_certificate               = "CERTIFICATE"
  keyname_certificate_chain         = "CERTIFICATE_CHAIN"
  keyname_private_key               = "CERTIFICATE_PRIVATE_KEY"
  kms_key_deletion_window_in_days   = 14
  kms_key_enable_key_rotation       = false
  secret_read_principals            = {}
  secret_update_sns_pub_principals  = {}
  secret_update_sns_sub_principals  = {}
  zone_id                           = join("", aws_route53_zone.public.*.zone_id)
}

data "external" "rds_combined_ca_bundle" {
  count   = module.context.enabled ? 1 : 0
  program = ["bash", "./scripts/fetch-rds-cert-bundle.sh"]
  query = {
    aws_region = data.aws_region.current.name
  }
}
