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
    key    = "${each.value.zip_name}.zip"
  }

  timeout                        = each.value.timeout
  memory_size                    = each.value.memory_size
  publish                        = true
  reserved_concurrent_executions = each.value.concurrency

  environment_variables = {
    SQS_SCHEDULER_TO_PUBLISHER_QUEUE_URL = module.aws_sqs["scheduler_to_publisher"].sqs_queue_id
    SQS_PUSH_QUEUE_URL                   = module.aws_sqs["push"].sqs_queue_id
    SQS_KAKAO_ALIMTALK_QUEUE_URL         = module.aws_sqs["kakao_alimtalk"].sqs_queue_id
    SQS_KAKAO_FRIENDTALK_QUEUE_URL       = module.aws_sqs["kakao_friendtalk"].sqs_queue_id
    SQS_TEXT_MESSAGE_QUEUE_URL           = module.aws_sqs["text_message"].sqs_queue_id
    SQS_CAMPAIGN_INSTANT_QUEUE_URL       = module.aws_sqs["campaign_instant"].sqs_queue_id
    SQS_EMAIL_QUEUE_URL                  = module.aws_sqs["email"].sqs_queue_id
    SQS_WEB_PUSH_QUEUE_URL               = module.aws_sqs["web_push"].sqs_queue_id
    SQS_WEBHOOK_QUEUE_URL                = module.aws_sqs["webhook"].sqs_queue_id
    SQS_CAFE24_WORKER_QUEUE_URL          = module.aws_sqs["cafe24_worker"].sqs_queue_id
    SQS_USER_CSV_MAILER_QUEUE_URL        = module.aws_sqs["user_csv_mailer"].sqs_queue_id
    NHNCLOUD_KAKAO_APP_KEY               = "DCM02ppx11irshpQ"
    NHNCLOUD_KAKAO_SECRET_KEY            = "vCKHOgzu"
    NHNCLOUD_TEXT_MESSAGE_APP_KEY        = "7G9Y9GfkkygcnVH9"
    NHNCLOUD_TEXT_MESSAGE_SECRET_KEY     = "LyBtXbFN"
    RDS_DATABASE                         = "postgres"
    RDS_HOSTNAME                         = "notifly-rds-proxy.proxy-cwvdx2o498bl.ap-northeast-2.rds.amazonaws.com"
    RDS_RW_HOSTNAME                      = "notifly-rds-proxy.proxy-cwvdx2o498bl.ap-northeast-2.rds.amazonaws.com"
    RDS_RO_HOSTNAME                      = "notifly-rds-proxy.proxy-cwvdx2o498bl.ap-northeast-2.rds.amazonaws.com"
    RDS_USERNAME                         = var.rds_username
    RDS_PASSWORD                         = var.rds_password
    NODE_NO_WARNINGS                     = "1"
    CAFE24_CLIENT_ID                     = "hdbI2jCsIR5thYPKwiHlCB"
    CAFE24_CLIENT_SECRET                 = "uVHVdpyeeEG1SVXqs3nYQO"
    REDIS_HOST                           = "clustercfg.notifly-cache.bcshxz.apn2.cache.amazonaws.com"
    CAFE24_NOTIFLY_API_ACCESS_KEY        = "cafe24-worker"
    CAFE24_NOTIFLY_API_SECRET_KEY        = "6o4J-K6REkPq7bcFH7r"
  }

  attach_policy_statements = true
  policy_statements = {
    sqs = {
      effect    = "Allow",
      actions   = ["sqs:SendMessage"],
      resources = ["*"]
    },
    ses = {
      effect    = "Allow",
      actions   = ["ses:SendTemplatedEmail"],
      resources = ["*"]
    },
    dynamodb = {
      effect    = "Allow",
      actions   = ["dynamodb:*"],
      resources = ["arn:aws:dynamodb:ap-northeast-2:702197142747:table/*"]
    },
    sns = {
      effect    = "Allow",
      actions   = ["sns:*"],
      resources = ["*"]
    },
    s3 = {
      effect    = "Allow",
      actions   = ["s3:*"],
      resources = ["*"]
    },
    glue = {
      effect    = "Allow",
      actions   = ["glue:*"],
      resources = ["*"]
    },
    athena = {
      effect    = "Allow"
      actions   = ["athena:*"]
      resources = ["*"]
    },
    kinesis = {
      effect    = "Allow",
      actions   = ["kinesis:*"],
      resources = ["arn:aws:kinesis:ap-northeast-2:702197142747:stream/*"]
    },
    firehose = {
      effect    = "Allow",
      actions   = ["firehose:*"],
      resources = ["*"]
    },
  }

  attach_policies    = true
  number_of_policies = 2

  policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole",
    "arn:aws:iam::aws:policy/AmazonKinesisFirehoseFullAccess"
  ]

  attach_network_policy  = true
  vpc_subnet_ids         = var.vpc_configurations.subnet_ids
  vpc_security_group_ids = var.vpc_configurations.security_group_ids
}

module "aws_sqs" {
  source                     = "terraform-aws-modules/sqs/aws"
  version                    = "~> 3.0"
  for_each                   = var.sqs
  name                       = each.value.name
  visibility_timeout_seconds = each.value.visibility_timeout_seconds
}

resource "aws_sqs_queue" "dlq" {
  for_each = var.sqs
  name     = "${each.value.name}-dlq"

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [module.aws_sqs[each.key].sqs_queue_arn]
  })
}

resource "aws_sqs_queue_redrive_policy" "redrive_policy" {
  for_each  = var.sqs
  queue_url = module.aws_sqs[each.key].sqs_queue_id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[each.key].arn
    maxReceiveCount     = 1
  })
}

// CloudWatch -> Scheduler

resource "aws_cloudwatch_event_rule" "every_five_minutes" {
  name                = "every-five-minutes"
  description         = "Fires every five minutes"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_rule" "every_one_minute" {
  name                = "every-one-minute"
  description         = "Fires every one minute"
  schedule_expression = "rate(1 minute)"
}


resource "aws_cloudwatch_event_target" "check_scheduler_every_five_minutes" {
  rule      = aws_cloudwatch_event_rule.every_five_minutes.name
  target_id = "check_scheduler"
  arn       = module.aws_lambda["scheduler"].lambda_function_arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_scheduler" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.aws_lambda["scheduler"].lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_five_minutes.arn
}

// scheduler_to_publisher SQS -> Publisher

resource "aws_lambda_event_source_mapping" "sqs_event_source_mapping_publisher" {
  event_source_arn                   = module.aws_sqs["scheduler_to_publisher"].sqs_queue_arn
  function_name                      = module.aws_lambda["publisher"].lambda_function_name
  batch_size                         = "30"
  maximum_batching_window_in_seconds = "0"
  enabled                            = true
}

// push SQS -> Delivery

resource "aws_lambda_event_source_mapping" "sqs_event_source_mapping_delivery" {
  event_source_arn                   = module.aws_sqs["push"].sqs_queue_arn
  function_name                      = module.aws_lambda["delivery"].lambda_function_name
  batch_size                         = "30"
  maximum_batching_window_in_seconds = "1"
  enabled                            = true
  scaling_config {
    maximum_concurrency = 50
  }
}


// kakao_alimtalk SQS -> Kakao_alimtalk delivery

resource "aws_lambda_event_source_mapping" "sqs_event_source_mapping_kakao_alimtalk_delivery" {
  event_source_arn                   = module.aws_sqs["kakao_alimtalk"].sqs_queue_arn
  function_name                      = module.aws_lambda["kakao_alimtalk_delivery"].lambda_function_name
  batch_size                         = "30"
  maximum_batching_window_in_seconds = "1"
  enabled                            = true
  scaling_config {
    maximum_concurrency = 50
  }
}



// kakao_friendtalk SQS -> Kakao_friendtalk delivery

resource "aws_lambda_event_source_mapping" "sqs_event_source_mapping_kakao_friendtalk_delivery" {
  event_source_arn                   = module.aws_sqs["kakao_friendtalk"].sqs_queue_arn
  function_name                      = module.aws_lambda["kakao_friendtalk_delivery"].lambda_function_name
  batch_size                         = "30"
  maximum_batching_window_in_seconds = "1"
  enabled                            = true
  scaling_config {
    maximum_concurrency = 50
  }
}



// text_message SQS -> Text_message delivery

resource "aws_lambda_event_source_mapping" "sqs_event_source_mapping_text_message_delivery" {
  event_source_arn                   = module.aws_sqs["text_message"].sqs_queue_arn
  function_name                      = module.aws_lambda["text_message_delivery"].lambda_function_name
  batch_size                         = "30"
  maximum_batching_window_in_seconds = "1"
  enabled                            = true
  scaling_config {
    maximum_concurrency = 50
  }
}


// Email Message SQS -> Email message delivery

resource "aws_lambda_event_source_mapping" "sqs_event_source_mapping_email_message_delivery" {
  event_source_arn                   = module.aws_sqs["email"].sqs_queue_arn
  function_name                      = module.aws_lambda["email_delivery"].lambda_function_name
  batch_size                         = "10"
  maximum_batching_window_in_seconds = "0"
  enabled                            = true
  scaling_config {
    maximum_concurrency = 2
  }
}

// Webhook Message SQS -> Webhook message delivery
resource "aws_lambda_event_source_mapping" "sqs_event_source_mapping_webhook_message_delivery" {
  event_source_arn                   = module.aws_sqs["webhook"].sqs_queue_arn
  function_name                      = module.aws_lambda["webhook_delivery"].lambda_function_name
  batch_size                         = "10"
  maximum_batching_window_in_seconds = "1"
  enabled                            = true
  scaling_config {
    maximum_concurrency = 50
  }
}

// Campaign instant SQS -> Instance scheduler

resource "aws_lambda_event_source_mapping" "sqs_event_source_mapping_instant_scheduler" {
  event_source_arn                   = module.aws_sqs["campaign_instant"].sqs_queue_arn
  function_name                      = module.aws_lambda["instant_scheduler"].lambda_function_name
  batch_size                         = "10"
  maximum_batching_window_in_seconds = "0"
  enabled                            = true
}

// Web push SQS -> Web push delivery

resource "aws_lambda_event_source_mapping" "sqs_event_source_mapping_web_push_delivery" {
  event_source_arn                   = module.aws_sqs["web_push"].sqs_queue_arn
  function_name                      = module.aws_lambda["web_push_delivery"].lambda_function_name
  batch_size                         = "10"
  maximum_batching_window_in_seconds = "1"
  enabled                            = true
  scaling_config {
    maximum_concurrency = 50
  }
}

// Cafe24 worker SQS -> Cafe24 worker

resource "aws_lambda_event_source_mapping" "sqs_event_source_mapping_cafe24_worker" {
  event_source_arn                   = module.aws_sqs["cafe24_worker"].sqs_queue_arn
  function_name                      = module.aws_lambda["cafe24_worker"].lambda_function_name
  batch_size                         = "10"
  maximum_batching_window_in_seconds = "0"
  enabled                            = true
}

// User CSV mailer SQS -> User CSV mailer

resource "aws_lambda_event_source_mapping" "sqs_event_source_mapping_user_csv_mailer" {
  event_source_arn                   = module.aws_sqs["user_csv_mailer"].sqs_queue_arn
  function_name                      = module.aws_lambda["user_csv_mailer"].lambda_function_name
  batch_size                         = "10"
  maximum_batching_window_in_seconds = "0"
  enabled                            = true
}

// CloudWatch -> Event Triggered Message Scheduler

resource "aws_cloudwatch_event_target" "call_event_triggered_message_scheduler_every_one_minute" {
  rule      = aws_cloudwatch_event_rule.every_one_minute.name
  target_id = "call_event_triggered_message_scheduler"
  arn       = module.aws_lambda["event-triggered-message-scheduler"].lambda_function_arn
}

// CloudWatch -> Cafe24 App Push Notification Worker
resource "aws_cloudwatch_event_target" "call_cafe24_app_push_notification_worker_every_one_minute" {
  rule      = aws_cloudwatch_event_rule.every_one_minute.name
  target_id = "call_cafe24_app_push_notification_worker"
  arn       = module.aws_lambda["cafe24_app_push_notification_worker"].lambda_function_arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_event_triggered_message_scheduler" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.aws_lambda["event-triggered-message-scheduler"].lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_one_minute.arn
}
resource "aws_lambda_permission" "allow_cloudwatch_to_call_cafe24_app_push_notification_worker" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.aws_lambda["cafe24_app_push_notification_worker"].lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_one_minute.arn
}

// Etc

data "aws_iam_policy" "lambda_basic_execution_role_policy" {
  name = "AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "lambda_iam_role" {
  name_prefix = "LambdaSQSRole-"
  managed_policy_arns = [
    data.aws_iam_policy.lambda_basic_execution_role_policy.arn,
    aws_iam_policy.lambda_policy.arn
  ]

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "lambda_policy_document" {
  statement {

    effect = "Allow"

    actions = [
      "sqs:SendMessage*"
    ]

    resources = [
      module.aws_sqs["push"].sqs_queue_arn,
      module.aws_sqs["scheduler_to_publisher"].sqs_queue_arn,
      module.aws_sqs["kakao_alimtalk"].sqs_queue_arn,
      module.aws_sqs["kakao_friendtalk"].sqs_queue_arn,
      module.aws_sqs["email"].sqs_queue_arn,
      module.aws_sqs["text_message"].sqs_queue_arn,
      module.aws_sqs["campaign_instant"].sqs_queue_arn,
      module.aws_sqs["web_push"].sqs_queue_arn,
      module.aws_sqs["cafe24_worker"].sqs_queue_arn
    ]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name_prefix = "lambda_policy"
  path        = "/"
  policy      = data.aws_iam_policy_document.lambda_policy_document.json
}
