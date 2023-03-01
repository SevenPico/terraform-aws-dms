module "sns_topic" {
  source  = "registry.terraform.io/SevenPicoForks/sns-topic/aws"
  version = "2.0.0"

  sqs_dlq_enabled    = false
  fifo_topic         = false
  fifo_queue_enabled = false
  encryption_enabled = false

  allowed_aws_services_for_sns_published = [
    "cloudwatch.amazonaws.com",
    "dms.amazonaws.com"
  ]

  context = module.context.self
}
