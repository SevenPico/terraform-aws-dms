locals {
  enabled = module.context.enabled
}

resource "aws_dms_event_subscription" "default" {
  count = local.enabled ? 1 : 0

  name             = module.context.id
  enabled          = var.event_subscription_enabled
  event_categories = var.event_categories
  source_type      = var.source_type
  source_ids       = var.source_ids
  sns_topic_arn    = var.sns_topic_arn

  tags = module.context.tags
}
