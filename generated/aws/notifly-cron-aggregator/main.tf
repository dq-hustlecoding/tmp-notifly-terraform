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
  timeout     = each.value.timeout
  memory_size = 512
  publish     = true
  environment_variables = {
    RDS_DATABASE                     = "postgres"
    RDS_HOSTNAME                     = "notifly-rds-proxy.proxy-cwvdx2o498bl.ap-northeast-2.rds.amazonaws.com"
    RDS_RW_HOSTNAME                  = "notifly-rds-proxy.proxy-cwvdx2o498bl.ap-northeast-2.rds.amazonaws.com"
    RDS_RO_HOSTNAME                  = "notifly-rds-proxy.proxy-cwvdx2o498bl.ap-northeast-2.rds.amazonaws.com"
    RDS_USERNAME                     = var.rds_username
    RDS_PASSWORD                     = var.rds_password
    RDS_CONNECTION_STRING            = "postgres://postgres:X80428v5h9l1QwuACZoV@notifly-rds-proxy.proxy-cwvdx2o498bl.ap-northeast-2.rds.amazonaws.com:5432/postgres"
    RDS_RW_CONNECTION_STRING         = "postgres://postgres:X80428v5h9l1QwuACZoV@notifly-rds-proxy.proxy-cwvdx2o498bl.ap-northeast-2.rds.amazonaws.com:5432/postgres"
    RDS_RO_CONNECTION_STRING         = "postgres://postgres:X80428v5h9l1QwuACZoV@notifly-rds-proxy.proxy-cwvdx2o498bl.ap-northeast-2.rds.amazonaws.com:5432/postgres"
    PORTONE_API_KEY                  = "0101215005813140"
    PORTONE_API_SECRET               = "MdgRTv3e8BBb8hAlfs8nR9ucOlaEAyld5yHVONiYxf0gEdVSmcmWYw2anLRweHeVnRPH7N8qk3LcN6p4"
    CAFE24_CLIENT_ID                 = "hdbI2jCsIR5thYPKwiHlCB"
    CAFE24_CLIENT_SECRET             = "uVHVdpyeeEG1SVXqs3nYQO"
    NHNCLOUD_KAKAO_APP_KEY           = "DCM02ppx11irshpQ"
    NHNCLOUD_KAKAO_SECRET_KEY        = "vCKHOgzu"
    NHNCLOUD_TEXT_MESSAGE_APP_KEY    = "7G9Y9GfkkygcnVH9"
    NHNCLOUD_TEXT_MESSAGE_SECRET_KEY = "LyBtXbFN"
  }

  attach_policy_statements = true
  policy_statements = {
    dynamodb = {
      effect    = "Allow",
      actions   = ["dynamodb:*"],
      resources = ["arn:aws:dynamodb:ap-northeast-2:702197142747:table/*"]
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
    }
    firehose = {
      effect    = "Allow",
      actions   = ["firehose:*"],
      resources = ["*"]
    },
    lambda = {
      effect    = "Allow",
      actions   = ["lambda:InvokeFunction"],
      resources = ["*"]
    }
    kinesis = {
      effect    = "Allow",
      actions   = ["kinesis:*"],
      resources = ["*"]
    }
  }

  attach_policies    = true
  number_of_policies = 1

  policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole",
    "arn:aws:iam::aws:policy/AmazonKinesisFirehoseFullAccess"
  ]

  attach_network_policy  = true
  vpc_subnet_ids         = var.vpc_configurations.subnet_ids
  vpc_security_group_ids = var.vpc_configurations.security_group_ids
}

// CloudWatch -> Lambda

resource "aws_cloudwatch_event_rule" "every_ten_minutes" {
  name                = "every-ten-minutes"
  description         = "Fires every ten minutes"
  schedule_expression = "rate(10 minutes)"
}

resource "aws_cloudwatch_event_rule" "every_five_minutes" {
  name                = "every-five-minutes"
  description         = "Fires every five minutes"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_rule" "every_hour" {
  name                = "every-hour"
  description         = "Fires every one hour"
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_rule" "once_daily" {
  name                = "once-daily"
  description         = "Fires once a day at 00:00:00UTC"
  schedule_expression = "cron(0 0 * * ? *)"
}

resource "aws_cloudwatch_event_target" "schedule_every_hour_for_project_metadata_generator" {
  rule      = aws_cloudwatch_event_rule.every_hour.name
  target_id = "invoke_project_metadata_generator"
  arn       = module.aws_lambda["project-metadata-generator"].lambda_function_arn
}
resource "aws_cloudwatch_event_target" "schedule_every_ten_minutes_for_cafe24_token_refresher" {
  rule      = aws_cloudwatch_event_rule.every_ten_minutes.name
  target_id = "invoke_cafe24_token_refresher"
  arn       = module.aws_lambda["cafe24-token-refresher"].lambda_function_arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_cafe24_token_refresher" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.aws_lambda["cafe24-token-refresher"].lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_ten_minutes.arn
}

resource "aws_cloudwatch_event_target" "schedule_every_ten_minutes_for_notifly_nhn_delivery_result_collector" {
  rule      = aws_cloudwatch_event_rule.every_ten_minutes.name
  target_id = "invoke_notifly_nhn_delivery_result_collector"
  arn       = module.aws_lambda["notifly-nhn-delivery-result-collector"].lambda_function_arn
}


resource "aws_lambda_permission" "allow_cloudwatch_to_call_notifly_nhn_delivery_result_collector" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.aws_lambda["notifly-nhn-delivery-result-collector"].lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_ten_minutes.arn
}

resource "aws_cloudwatch_event_target" "schedule_every_ten_minutes_for_anomaly_delivery_monitoring" {
  rule      = aws_cloudwatch_event_rule.every_ten_minutes.name
  target_id = "invoke_anomaly_delivery_monitoring"
  arn       = module.aws_lambda["anomaly-delivery-monitoring"].lambda_function_arn
}
resource "aws_lambda_permission" "allow_cloudwatch_to_call_anomaly_delivery_monitoring" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.aws_lambda["anomaly-delivery-monitoring"].lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_ten_minutes.arn
}

resource "aws_cloudwatch_event_target" "schedule_every_five_minutes" {
  rule      = aws_cloudwatch_event_rule.every_five_minutes.name
  target_id = "invoke_project_cleaner"
  arn       = module.aws_lambda["project-cleaner"].lambda_function_arn
}

resource "aws_cloudwatch_event_target" "schedule_every_day_for_event_table_partition_generator" {
  rule      = aws_cloudwatch_event_rule.once_daily.name
  target_id = "invoke_event_table_partition_generator"
  arn       = module.aws_lambda["event-table-partition-generator"].lambda_function_arn
}
resource "aws_cloudwatch_event_target" "schedule_every_day_for_notifly_delivery_analysis_generator" {
  rule      = aws_cloudwatch_event_rule.once_daily.name
  target_id = "invoke_notifly_delivery_analysis_generator"
  arn       = module.aws_lambda["notifly-delivery-analysis-generator"].lambda_function_arn
}
resource "aws_cloudwatch_event_target" "schedule_every_day_for_payment_executor" {
  rule      = aws_cloudwatch_event_rule.once_daily.name
  target_id = "invoke_payment_executor"
  arn       = module.aws_lambda["payment-executor"].lambda_function_arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_project_metadata_generator" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.aws_lambda["project-metadata-generator"].lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_hour.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_project_cleaner" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.aws_lambda["project-cleaner"].lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_five_minutes.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_event_table_partition_generator" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.aws_lambda["event-table-partition-generator"].lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.once_daily.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_payment_executor" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.aws_lambda["payment-executor"].lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.once_daily.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_notifly_delivery_analysis_generator" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.aws_lambda["notifly-delivery-analysis-generator"].lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.once_daily.arn
}
