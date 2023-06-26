#------------------------------------------------------------------------------
# VPC Context
#------------------------------------------------------------------------------
module "vpc_context" {
  source  = "registry.terraform.io/SevenPico/context/null"
  version = "2.0.0"
  context = module.context.self
  name    = "vpc"
}

module "vpc_subnets_context" {
  source     = "registry.terraform.io/SevenPico/context/null"
  version    = "2.0.0"
  context    = module.vpc_context.self
  attributes = ["subnet"]
}

module "vpc_endpoint_sg_context" {
  source  = "registry.terraform.io/SevenPico/context/null"
  version = "2.0.0"
  context = module.vpc_context.self
}

locals {
  gateway_vpc_endpoints   = [] #["s3"]
  interface_vpc_endpoints = {}
  # {
  #   "ec2" : {
  #     private_dns_enabled = true
  #   }
  #   "ec2messages" : {
  #     private_dns_enabled = true
  #   }
  #   "ecs" : {
  #     private_dns_enabled = true
  #   }
  #   "logs" : {
  #     private_dns_enabled = true
  #   }
  #   "s3" : {
  #     private_dns_enabled = false
  #   }
  #   "secretsmanager" : {
  #     private_dns_enabled = true
  #   }
  #   "ecr.dkr" : {
  #     private_dns_enabled = true
  #   }
  #   "ecr.api" : {
  #     private_dns_enabled = true
  #   }
  #   "ssm" : {
  #     private_dns_enabled = true
  #   }
  #   "ssmmessages" : {
  #     private_dns_enabled = true
  #   }
  # }
}


#------------------------------------------------------------------------------
# VPC
#------------------------------------------------------------------------------
module "vpc" {
  source  = "registry.terraform.io/SevenPico/vpc/aws"
  version = "3.0.1"
  context = module.vpc_context.self

  assign_generated_ipv6_cidr_block          = false
  default_network_acl_deny_all              = false
  default_route_table_no_routes             = false
  default_security_group_deny_all           = true
  dns_hostnames_enabled                     = true
  dns_support_enabled                       = true
  instance_tenancy                          = "default"
  internet_gateway_enabled                  = true
  ipv4_additional_cidr_block_associations   = {}
  ipv4_cidr_block_association_timeouts      = null
  ipv4_primary_cidr_block                   = var.vpc_cidr_block
  ipv4_primary_cidr_block_association       = null
  ipv6_additional_cidr_block_associations   = {}
  ipv6_cidr_block_association_timeouts      = null
  ipv6_cidr_block_network_border_group      = null
  ipv6_egress_only_internet_gateway_enabled = false
  ipv6_primary_cidr_block_association       = null
}


##------------------------------------------------------------------------------
## VPC Flow Logs
##------------------------------------------------------------------------------
#resource "aws_flow_log" "s3" {
#  count                    = module.vpc_context.enabled && var.vpc_flow_logs_enabled && var.vpc_flow_logs_s3_bucket_arn != "" ? 1 : 0
#  log_destination          = var.vpc_flow_logs_s3_bucket_arn
#  log_destination_type     = "s3"
#  log_format               = var.vpc_flow_logs_log_format
#  max_aggregation_interval = var.vpc_flow_logs_max_aggregation_interval
#  traffic_type             = var.vpc_flow_logs_traffic_type
#  vpc_id                   = module.vpc.vpc_id
#}
#
#resource "aws_flow_log" "cloudwatch" {
#  count                    = module.vpc_context.enabled && var.vpc_flow_logs_enabled && var.vpc_flow_logs_cloudwatch_log_group_arn != "" ? 1 : 0
#  iam_role_arn             = var.vpc_flow_log_cloudwatch_log_group_iam_role_arn
#  log_destination          = var.vpc_flow_logs_cloudwatch_log_group_arn
#  log_destination_type     = "cloud-watch-logs"
#  log_format               = var.vpc_flow_logs_log_format
#  max_aggregation_interval = var.vpc_flow_logs_max_aggregation_interval
#  traffic_type             = var.vpc_flow_logs_traffic_type
#  vpc_id                   = module.vpc.vpc_id
#}
#

#------------------------------------------------------------------------------
# VPC Subnets
#------------------------------------------------------------------------------
module "vpc_subnets" {
  source  = "registry.terraform.io/SevenPico/dynamic-subnets/aws"
  version = "3.0.1"
  context = module.vpc_subnets_context.self

  availability_zone_attribute_style        = "short"
  availability_zone_ids                    = []
  availability_zones                       = var.availability_zones
  aws_route_create_timeout                 = "2m"
  aws_route_delete_timeout                 = "2m"
  igw_id                                   = [module.vpc.igw_id]
  ipv4_cidr_block                          = [var.vpc_cidr_block]
  ipv4_cidrs                               = []
  ipv4_enabled                             = true
  ipv4_private_instance_hostname_type      = "ip-name"
  ipv4_private_instance_hostnames_enabled  = false
  ipv4_public_instance_hostname_type       = "ip-name"
  ipv4_public_instance_hostnames_enabled   = false
  ipv6_cidr_block                          = []
  ipv6_cidrs                               = []
  ipv6_egress_only_igw_id                  = []
  ipv6_enabled                             = false
  ipv6_private_instance_hostnames_enabled  = false
  ipv6_public_instance_hostnames_enabled   = false
  map_public_ip_on_launch                  = true
  max_nats                                 = 1
  max_subnet_count                         = 1 // 0 means create 1 for each AZ
  metadata_http_endpoint_enabled           = false
  metadata_http_put_response_hop_limit     = 1
  metadata_http_tokens_required            = true
  nat_elastic_ips                          = []
  nat_gateway_enabled                      = true
  nat_instance_ami_id                      = []
  nat_instance_cpu_credits_override        = ""
  nat_instance_root_block_device_encrypted = true
  nat_instance_type                        = "t3.micro"
  open_network_acl_ipv4_rule_number        = 100
  open_network_acl_ipv6_rule_number        = 111
  outpost_arn                              = null
  private_assign_ipv6_address_on_creation  = true
  private_dns64_nat64_enabled              = null
  private_label                            = "private"
  private_open_network_acl_enabled         = true
  private_route_table_enabled              = true
  private_subnets_enabled                  = true
  public_assign_ipv6_address_on_creation   = true
  public_dns64_nat64_enabled               = false
  public_label                             = "public"
  public_open_network_acl_enabled          = true
  public_route_table_enabled               = true
  public_route_table_ids                   = []
  public_route_table_per_subnet_enabled    = null
  public_subnets_additional_tags           = {}
  public_subnets_enabled                   = true
  root_block_device_encrypted              = true
  route_create_timeout                     = "5m"
  route_delete_timeout                     = "10m"
  subnet_create_timeout                    = "10m"
  subnet_delete_timeout                    = "10m"
  subnet_type_tag_key                      = "Type"
  subnet_type_tag_value_format             = "%s"
  subnets_per_az_count                     = 1
  subnets_per_az_names                     = ["common"]
  vpc_id                                   = module.vpc.vpc_id
  private_subnets_additional_tags          = {}
  nat_instance_enabled                     = false
}


#------------------------------------------------------------------------------
# VPC Endpoint Security Groups
#------------------------------------------------------------------------------
module "vpc_endpoint_sg" {
  source     = "registry.terraform.io/SevenPicoForks/security-group/aws"
  version    = "3.0.0"
  context    = module.vpc_endpoint_sg_context.self
  attributes = ["vpc", "endpoint"]

  allow_all_egress              = false
  create_before_destroy         = false
  inline_rules_enabled          = false
  revoke_rules_on_delete        = false
  rule_matrix                   = []
  rules_map                     = {}
  security_group_create_timeout = "5m"
  security_group_delete_timeout = "5m"
  security_group_description    = "Allow access to Interface VPC Private Link Endpoint."
  security_group_name           = []
  target_security_group_id      = []

  vpc_id = module.vpc.vpc_id
  rules = [
    {
      description = "Security Group Rule for Interface VPC Private Link Endpoint."
      type        = "ingress"
      protocol    = "TCP"
      cidr_blocks = [module.vpc.vpc_cidr_block]
      from_port   = 443
      to_port     = 443
      self        = null
    }
  ]
}


#------------------------------------------------------------------------------
# VPC Endpoints
#------------------------------------------------------------------------------
module "vpc_endpoints" {
  source  = "registry.terraform.io/cloudposse/vpc/aws//modules/vpc-endpoints"
  version = "0.28.1"
  context = module.vpc_context.legacy
  enabled = module.vpc_context.enabled

  vpc_id = module.vpc.vpc_id

  gateway_vpc_endpoints = {
    for key in local.gateway_vpc_endpoints :
    key => {
      name = key
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect    = "Allow"
            Action    = "*"
            Principal = "*"
            Resource  = "*"
          }
        ]
      })
    }
  }

  interface_vpc_endpoints = {
    for key, value in local.interface_vpc_endpoints :
    key => {
      name                = key
      subnet_ids          = module.vpc_subnets.private_subnet_ids
      security_group_ids  = [module.vpc_endpoint_sg.id]
      private_dns_enabled = value["private_dns_enabled"]
      policy = lookup(value, "policy", jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect    = "Allow"
            Action    = "*"
            Principal = "*"
            Resource  = "*"
          }
        ]
      }))
    }
  }
}

resource "aws_vpc_endpoint_route_table_association" "vpc_gateway_endpoint" {
  count           = module.vpc_context.enabled && length(module.vpc_endpoints.gateway_vpc_endpoints) > 0 ? length(var.availability_zones) : 0
  route_table_id  = module.vpc_subnets.private_route_table_ids[count.index]
  vpc_endpoint_id = module.vpc_endpoints.gateway_vpc_endpoints[0].id
}
