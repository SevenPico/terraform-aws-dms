data "aws_route53_zone" "root" {
  count = module.context.enabled ? 1 : 0
  name  = var.root_domain

}

# ------------------------------------------------------------------------------
# Public Zone
# ------------------------------------------------------------------------------
resource "aws_route53_zone" "public" {
  count = module.context.enabled ? 1 : 0
  tags  = module.context.tags
  name  = module.context.domain_name
}

resource "aws_route53_record" "parent_name_servers" {
  count    = module.context.enabled ? 1 : 0

  zone_id = data.aws_route53_zone.root[0].id
  name    = module.context.domain_name
  records = one(aws_route53_zone.public[*].name_servers)
  type    = "NS"
  ttl     = "60"
}


# ------------------------------------------------------------------------------
# Private Zone
# ------------------------------------------------------------------------------
resource "aws_route53_zone" "private" {
  count = module.context.enabled ? 1 : 0
  tags  = module.context.tags
  name  = module.context.domain_name

  vpc {
    vpc_id = module.vpc.vpc_id
  }
  lifecycle {
    # This is required so that future updates don't attempt to remove VPC associations made
    # by the null_resource commands below that create the associations outside of the terraform
    ignore_changes = [vpc]
  }
}
