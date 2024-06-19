locals {
  account_id           = "702197142747"
  amplitude_account_id = "358203115967"
  role_name            = "amplitude-kinesis-role"
  policy_name          = "amplitude-kinesis-policy"
}

module "aws_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 2.0"

  for_each = var.lambdas

  function_name  = each.value.name
  description    = each.value.description
  handler        = "${each.value.handler_file_name}.handler"
  architectures  = ["arm64"]
  runtime        = "nodejs18.x"
  create_package = false
  s3_existing_package = {
    bucket = "notifly-lambda-builds"
    key    = "${each.value.name}.zip"
  }
  timeout     = 300
  memory_size = 512
  publish     = true
  environment_variables = {
    RDS_DATABASE     = "postgres"
    RDS_HOSTNAME     = "notifly-rds-proxy.proxy-cwvdx2o498bl.ap-northeast-2.rds.amazonaws.com"
    RDS_RW_HOSTNAME  = "notifly-rds-proxy.proxy-cwvdx2o498bl.ap-northeast-2.rds.amazonaws.com"
    RDS_RO_HOSTNAME  = "notifly-rds-proxy.proxy-cwvdx2o498bl.ap-northeast-2.rds.amazonaws.com"
    RDS_USERNAME     = var.rds_username
    RDS_PASSWORD     = var.rds_password
    NODE_NO_WARNINGS = "1"
  }

  attach_policy_statements = true
  policy_statements = {
    dynamodb = {
      effect    = "Allow",
      actions   = ["dynamodb:*"],
      resources = ["arn:aws:dynamodb:ap-northeast-2:702197142747:table/*"]
    },
    kinesis = {
      effect    = "Allow",
      actions   = ["kinesis:*"],
      resources = ["arn:aws:kinesis:ap-northeast-2:702197142747:stream/*"]
    },
  }

  attach_policies    = true
  number_of_policies = 1

  policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole",
  ]

  attach_network_policy  = true
  vpc_subnet_ids         = var.vpc_configurations.subnet_ids
  vpc_security_group_ids = var.vpc_configurations.security_group_ids
}

// Kinesis for Amplitude event streaming

resource "aws_kinesis_stream" "external_event_streaming" {
  name             = "notifly-external-event-streaming"
  shard_count      = 1
  retention_period = 48

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
}

resource "aws_iam_role" "amplitude_role" {
  name = local.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.amplitude_account_id}:root"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "amplitude_policy" {
  name = local.policy_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kinesis:PutRecord",
          "kinesis:PutRecords",
          "iam:SimulatePrincipalPolicy"
        ]
        Effect = "Allow"
        Resource = [
          var.kds.arn,
          "arn:aws:iam::${local.account_id}:role/${local.role_name}"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "amplitude_policy_attachment" {
  policy_arn = aws_iam_policy.amplitude_policy.arn
  role       = aws_iam_role.amplitude_role.name
}

resource "aws_lambda_event_source_mapping" "kinesis_event_source" {
  for_each = var.lambdas

  event_source_arn               = var.kds.arn
  function_name                  = module.aws_lambda[each.key].lambda_function_arn
  batch_size                     = 100
  bisect_batch_on_function_error = true
  starting_position              = "LATEST"
  maximum_record_age_in_seconds  = "86400"
  maximum_retry_attempts         = "1"
  parallelization_factor         = "3"
}

data "aws_region" "current" {}
