locals {
  security_group_rules = [
    {
      type        = "ingress"
      from_port   = 0
      to_port     = 65535
      protocol    = "all"
      cidr_blocks = [local.vpc_cidr_block]
    }
  ]
}

module "security_group" {
  source  = "registry.terraform.io/SevenPicoForks/security-group/aws"
  version = "3.0.0"

  vpc_id                     = local.vpc_id
  create_before_destroy      = false
  allow_all_egress           = true
  rules                      = local.security_group_rules
  preserve_security_group_id = false

  attributes = ["common"]
  context    = module.context.self
}
