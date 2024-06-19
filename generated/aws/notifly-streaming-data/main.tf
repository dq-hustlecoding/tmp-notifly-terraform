/* ========================================= Rest API and Custom Domain Mapping ============================================ */

resource "aws_api_gateway_rest_api" "kds-proxy-rest-api" {
  name                         = "kinesis-proxy-api"
  description                  = "API Gateway proxy for Kinesis Data Stream"
  api_key_source               = "HEADER"
  disable_execute_api_endpoint = false
  endpoint_configuration {
    types = ["EDGE"]
  }
  minimum_compression_size = -1
}

data "aws_acm_certificate" "notifly-cert" {
  domain   = "notifly.tech"
  statuses = ["ISSUED"]
}

resource "aws_api_gateway_domain_name" "kds-proxy-api-domain-name" {
  regional_certificate_arn = data.aws_acm_certificate.notifly-cert.arn
  domain_name              = "log.notifly.tech"
  security_policy          = "TLS_1_2"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "kds-proxy-api-base-path-mapping" {
  api_id      = aws_api_gateway_rest_api.kds-proxy-rest-api.id
  domain_name = aws_api_gateway_domain_name.kds-proxy-api-domain-name.domain_name
  stage_name  = var.api_stage_names.prod
}

/* ========================================= API Gateway Resources and Methods ============================================ */

resource "aws_api_gateway_resource" "root-resource" {
  parent_id   = ""
  path_part   = ""
  rest_api_id = aws_api_gateway_rest_api.kds-proxy-rest-api.id
}

resource "aws_api_gateway_resource" "records-resource" {
  parent_id   = aws_api_gateway_resource.root-resource.id
  path_part   = "records"
  rest_api_id = aws_api_gateway_rest_api.kds-proxy-rest-api.id
}

resource "aws_api_gateway_integration" "records-post" {
  cache_namespace         = aws_api_gateway_resource.records-resource.id
  connection_type         = "INTERNET"
  credentials             = aws_iam_role.event-streaming-apigw-execution-role.arn
  http_method             = "POST"
  integration_http_method = "POST"
  passthrough_behavior    = "NEVER"

  request_parameters = {
    "integration.request.header.Content-Type" = "'x-amz-json-1.1'"
  }
  request_templates = {
    "application/json" = "{ \"StreamName\": \"${var.kds.name}\", \"Records\": [ #foreach($elem in $input.path('$.records')) { \"Data\": \"$util.base64Encode($elem.data)\", \"PartitionKey\": \"$elem.partitionKey\"}#if($foreach.hasNext),#end #end ] }"
  }
  resource_id          = aws_api_gateway_resource.records-resource.id
  rest_api_id          = aws_api_gateway_rest_api.kds-proxy-rest-api.id
  timeout_milliseconds = 29000
  type                 = "AWS"
  uri                  = "arn:aws:apigateway:ap-northeast-2:kinesis:action/PutRecords"
}

resource "aws_api_gateway_request_validator" "records-post-request-validator" {
  name                        = "records-post-request-validator"
  rest_api_id                 = aws_api_gateway_rest_api.kds-proxy-rest-api.id
  validate_request_body       = true
  validate_request_parameters = false
}

resource "aws_api_gateway_method" "records-post" {
  api_key_required = "false"
  authorization    = "NONE"
  http_method      = "POST"
  request_models = {
    "application/json" = "PutRecordsModel"
  }
  request_validator_id = aws_api_gateway_request_validator.records-post-request-validator.id
  resource_id          = aws_api_gateway_resource.records-resource.id
  rest_api_id          = aws_api_gateway_rest_api.kds-proxy-rest-api.id
}

resource "aws_api_gateway_integration_response" "records-post-200" {
  http_method = "POST"
  resource_id = aws_api_gateway_resource.records-resource.id
  rest_api_id = aws_api_gateway_rest_api.kds-proxy-rest-api.id
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
    "method.response.header.Content-Type"                = "'application/json'"
  }
}

resource "aws_api_gateway_integration_response" "records-post-500" {
  http_method = "POST"
  resource_id = aws_api_gateway_resource.records-resource.id
  rest_api_id = aws_api_gateway_rest_api.kds-proxy-rest-api.id
  response_templates = {
    "text/html" = "Error"
  }
  selection_pattern = "500"
  status_code       = "500"
}

resource "aws_api_gateway_method_response" "records-post-200" {
  http_method = "POST"
  resource_id = aws_api_gateway_resource.records-resource.id
  response_parameters = {
    "method.response.header.Content-Type"                = true
    "method.response.header.Access-Control-Allow-Origin" = true
  }
  rest_api_id = aws_api_gateway_rest_api.kds-proxy-rest-api.id
  status_code = "200"
}

resource "aws_api_gateway_method_response" "records-post-500" {
  http_method = "POST"
  resource_id = aws_api_gateway_resource.records-resource.id
  rest_api_id = aws_api_gateway_rest_api.kds-proxy-rest-api.id
  status_code = "500"
}

resource "aws_api_gateway_method" "records-options" {
  http_method      = "OPTIONS"
  resource_id      = aws_api_gateway_resource.records-resource.id
  authorization    = "NONE"
  rest_api_id      = aws_api_gateway_rest_api.kds-proxy-rest-api.id
  api_key_required = false
}

resource "aws_api_gateway_integration" "records-options" {
  http_method          = "OPTIONS"
  resource_id          = aws_api_gateway_resource.records-resource.id
  rest_api_id          = aws_api_gateway_rest_api.kds-proxy-rest-api.id
  type                 = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration_response" "records-options" {
  http_method = "OPTIONS"
  resource_id = aws_api_gateway_resource.records-resource.id
  rest_api_id = aws_api_gateway_rest_api.kds-proxy-rest-api.id
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Notifly-SDK-Version,X-Notifly-SDK-Wrapper'"
    "method.response.header.Access-Control-Allow-Methods" = "'*'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_method_response" "records-options" {
  http_method = "OPTIONS"
  resource_id = aws_api_gateway_resource.records-resource.id
  rest_api_id = aws_api_gateway_rest_api.kds-proxy-rest-api.id
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
  response_models = {
    "application/json" = "Empty"
  }
}

/* ========================================= API Gateway Deployment and Stage ============================================ */

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id       = aws_api_gateway_rest_api.kds-proxy-rest-api.id
  stage_name        = var.api_stage_names.prod
  stage_description = md5(file("main.tf"))
  description       = "Deployed at ${timestamp()} from Terraform"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod-stage" {
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.event-streaming-api-access-cloudwatch-log-group.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      user           = "$context.identity.user"
      caller         = "$context.identity.caller"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  cache_cluster_enabled = false
  xray_tracing_enabled  = true

  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.kds-proxy-rest-api.id
  stage_name    = var.api_stage_names.prod
  description   = aws_api_gateway_deployment.deployment.description
}

/* ========================================= API Gateway Schema Models ============================================ */

resource "aws_api_gateway_model" "error-model" {
  content_type = "application/json"
  description  = "This is a default error schema model"
  name         = "Error"
  rest_api_id  = aws_api_gateway_rest_api.kds-proxy-rest-api.id
  schema       = "{\n  \"$schema\" : \"http://json-schema.org/draft-04/schema#\",\n  \"title\" : \"Error Schema\",\n  \"type\" : \"object\",\n  \"properties\" : {\n    \"message\" : { \"type\" : \"string\" }\n  }\n}"
}

resource "aws_api_gateway_model" "empty-model" {
  content_type = "application/json"
  description  = "This is a default empty schema model"
  name         = "Empty"
  rest_api_id  = aws_api_gateway_rest_api.kds-proxy-rest-api.id
  schema       = "{\n  \"$schema\": \"http://json-schema.org/draft-04/schema#\",\n  \"title\" : \"Empty Schema\",\n  \"type\" : \"object\"\n}"
}

resource "aws_api_gateway_model" "put-records-model" {
  content_type = "application/json"
  description  = "PutRecords proxy payload data"
  name         = "PutRecordsModel"
  rest_api_id  = aws_api_gateway_rest_api.kds-proxy-rest-api.id
  schema       = "{\"$schema\":\"http://json-schema.org/draft-04/schema#\",\"title\":\"PutRecords proxy payload data\",\"type\":\"object\",\"required\":[\"records\"],\"properties\":{\"records\":{\"type\":\"array\",\"items\":{\"type\":\"object\",\"required\":[\"data\",\"partitionKey\"],\"properties\":{\"data\":{\"type\":\"string\"},\"partitionKey\":{\"type\":\"string\"}}}}}}"
}

/* ========================================= Cloudwatch Logs ============================================ */

// For KDS consumer lambda logs
resource "aws_cloudwatch_log_group" "kds-consumer-cloudwatch-log-group" {
  name              = "/aws/lambda/${var.kds_consumer.name}"
  retention_in_days = 30
}

// For API Gateway access logs
resource "aws_cloudwatch_log_group" "event-streaming-api-access-cloudwatch-log-group" {
  name              = "event-streaming-api-access-logs"
  retention_in_days = 30
}

/* ========================================= Cognito User Pool ============================================ */

resource "aws_cognito_user_pool" "event-streaming-api-user-pool" {
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 2
    }

    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  deletion_protection = "INACTIVE"

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  mfa_configuration = "OFF"
  name              = "ApiUserPool7811AFAD-loZpbIY7ecbB"

  password_policy {
    minimum_length                   = 6
    require_lowercase                = false
    require_numbers                  = false
    require_symbols                  = false
    require_uppercase                = false
    temporary_password_validity_days = 1
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true

    string_attribute_constraints {
      max_length = "2048"
      min_length = "0"
    }
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "given_name"
    required                 = true

    string_attribute_constraints {
      max_length = "2048"
      min_length = "0"
    }
  }

  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_message        = "The verification code to your new account is {####}"
    email_subject        = "Verify your new account"
    sms_message          = "The verification code to your new account is {####}"
  }
}

/* ========================================= IAM Roles and Policies ============================================ */

resource "aws_iam_role" "event-streaming-apigw-execution-role" {
  max_session_duration = 3600
  name                 = "event-streaming-apigw-execution-role"
  path                 = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "EventStreamingApiGwExecutionRolePolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["kinesis:ListShards", "kinesis:PutRecord", "kinesis:PutRecords"]
          Effect   = "Allow"
          Resource = var.kds.arn
        }
      ]
    })
  }
}

resource "aws_iam_role" "kds-consumer" {
  max_session_duration = 3600
  name                 = "kds-consumer"
  path                 = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "KdsConsumerRolePolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["xray:PutTraceSegments", "xray:PutTelemetryRecords"]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = ["kinesis:DescribeStream", "kinesis:DescribeStreamSummary", "kinesis:GetRecords", "kinesis:GetShardIterator", "kinesis:ListShards", "kinesis:SubscribeToShard", "kinesis:ListStreams", "kinesis:PutRecords", "kinesis:PutRecord"]
          Effect = "Allow"
          Resource = [
            "${var.kds.arn}",
            "${aws_kinesis_stream.message-events-stream.arn}",
            "${aws_kinesis_stream.triggering-events-stream.arn}"
          ]
        },
        {
          Action   = ["dynamodb:BatchGetItem", "dynamodb:Scan", "dynamodb:GetShardIterator", "dynamodb:GetItem", "dynamodb:GetRecords"]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action   = ["sqs:SendMessage", "sqs:GetQueueAttributes", "sqs:GetQueueUrl"]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action   = ["kms:Decrypt"]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action   = ["firehose:*"]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }

  inline_policy {
    name = "KdsConsumerLogsPushRolePolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:DescribeLogGroups", "logs:DescribeLogStreams", "logs:PutLogEvents", "logs:GetLogEvents", "logs:FilterLogEvents"]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
}

/* ========================================= Kinesis Data Streams ============================================ */

resource "aws_kinesis_stream" "kds" {
  arn              = var.kds.arn
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
  name             = var.kds.name
  retention_period = var.kds.retention_period
  shard_count      = var.kds.shard_count

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
}

resource "aws_kinesis_stream" "message-events-stream" {
  name             = "notifly-message-events-stream"
  shard_count      = 8
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
}

resource "aws_kinesis_stream" "triggering-events-stream" {
  name             = "notifly-triggering-events-stream"
  shard_count      = 8
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
}


/* ========================================= Kinesis Data Stream Consumer Lambda ============================================ */

resource "aws_lambda_function" "kds-consumer" {
  architectures = ["arm64"]

  environment {
    variables = {
      AWS_SDK_USER_AGENT                       = "{ \"customUserAgent\": \"AwsSolution/SO0124/1.0.0\" }"
      SQS_PUSH_QUEUE_URL                       = "https://sqs.ap-northeast-2.amazonaws.com/702197142747/scheduled-batch-push-notification-queue"
      SQS_KAKAO_ALIMTALK_QUEUE_URL             = "https://sqs.ap-northeast-2.amazonaws.com/702197142747/scheduled-batch-kakao-alimtalk-queue"
      SQS_KAKAO_ALIMTALK_STATIC_IP_QUEUE_URL   = "https://sqs.ap-northeast-2.amazonaws.com/702197142747/scheduled-batch-kakao-alimtalk-static-ip-queue"
      SQS_KAKAO_FRIENDTALK_QUEUE_URL           = "https://sqs.ap-northeast-2.amazonaws.com/702197142747/scheduled-batch-kakao-friendtalk-queue"
      SQS_KAKAO_FRIENDTALK_STATIC_IP_QUEUE_URL = "https://sqs.ap-northeast-2.amazonaws.com/702197142747/scheduled-batch-kakao-friendtalk-static-ip-queue"
      SQS_TEXT_MESSAGE_QUEUE_URL               = "https://sqs.ap-northeast-2.amazonaws.com/702197142747/scheduled-batch-text-message-queue"
      SQS_TEXT_MESSAGE_STATIC_IP_QUEUE_URL     = "https://sqs.ap-northeast-2.amazonaws.com/702197142747/scheduled-batch-text-message-static-ip-queue"
      SQS_EMAIL_QUEUE_URL                      = "https://sqs.ap-northeast-2.amazonaws.com/702197142747/email-delivery-queue"
      SQS_WEBHOOK_QUEUE_URL                    = "https://sqs.ap-northeast-2.amazonaws.com/702197142747/webhook-delivery-queue"
      SQS_IN_APP_QUEUE_URL                     = "https://sqs.ap-northeast-2.amazonaws.com/702197142747/in-app-message-delivery-queue"
      SQS_CAMPAIGN_INSTANT_QUEUE_URL           = "https://sqs.ap-northeast-2.amazonaws.com/702197142747/insatnt-batch-scheduler-queue"
      SQS_WEB_PUSH_QUEUE_URL                   = "https://sqs.ap-northeast-2.amazonaws.com/702197142747/web-push-delivery-queue"
      RDS_DATABASE                             = "postgres"
      RDS_HOSTNAME                             = "notifly-rds-proxy.proxy-cwvdx2o498bl.ap-northeast-2.rds.amazonaws.com"
      RDS_RW_HOSTNAME                          = "notifly-rds-proxy.proxy-cwvdx2o498bl.ap-northeast-2.rds.amazonaws.com"
      RDS_RO_HOSTNAME                          = "notifly-rds-proxy.proxy-cwvdx2o498bl.ap-northeast-2.rds.amazonaws.com"
      RDS_USERNAME                             = var.rds_username
      RDS_PASSWORD                             = var.rds_password
      NODE_NO_WARNINGS                         = "1"
      REDIS_HOST                               = "clustercfg.notifly-cache.bcshxz.apn2.cache.amazonaws.com"
    }
  }

  ephemeral_storage {
    size = 512
  }

  function_name                  = var.kds_consumer.name
  description                    = var.kds_consumer.description
  handler                        = var.kds_consumer.handler
  memory_size                    = var.kds_consumer.memory_size
  package_type                   = var.kds_consumer.package_type
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.kds-consumer.arn
  runtime                        = var.kds_consumer.runtime
  s3_bucket                      = var.kds_consumer.s3_bucket
  s3_key                         = var.kds_consumer.s3_key
  timeout                        = 300

  tracing_config {
    mode = "Active"
  }

  vpc_config {
    subnet_ids         = var.vpc_configurations.subnet_ids
    security_group_ids = var.vpc_configurations.security_group_ids
  }
}

resource "aws_lambda_event_source_mapping" "kinesis-event-source-mapping" {
  batch_size                     = 100
  bisect_batch_on_function_error = true
  destination_config {
    on_failure {
      destination_arn = aws_sqs_queue.kds-consumer-dlq.arn
    }
  }
  enabled                            = true
  event_source_arn                   = var.kds.arn
  function_name                      = aws_lambda_function.kds-consumer.arn
  maximum_batching_window_in_seconds = 0
  maximum_record_age_in_seconds      = 86400
  maximum_retry_attempts             = 1
  parallelization_factor             = 1
  starting_position                  = "LATEST"
  tumbling_window_in_seconds         = 0
}

resource "aws_sqs_queue" "kds-consumer-dlq" {
  content_based_deduplication       = false
  delay_seconds                     = 0
  fifo_queue                        = false
  kms_data_key_reuse_period_seconds = 300
  kms_master_key_id                 = "alias/aws/sqs"
  max_message_size                  = 262144
  message_retention_seconds         = 345600
  name                              = "kds-consumer-dlq"

  policy = <<POLICY
{
  "Statement": [
    {
      "Action": [
        "sqs:DeleteMessage",
        "sqs:ReceiveMessage",
        "sqs:SendMessage",
        "sqs:GetQueueAttributes",
        "sqs:RemovePermission",
        "sqs:AddPermission",
        "sqs:SetQueueAttributes"
      ],
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::702197142747:root"
      },
      "Resource": "arn:aws:sqs:ap-northeast-2:702197142747:kds-consumer-dlq",
      "Sid": "QueueOwnerOnlyAccess"
    },
    {
      "Action": "SQS:*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      },
      "Effect": "Deny",
      "Principal": {
        "AWS": "*"
      },
      "Resource": "arn:aws:sqs:ap-northeast-2:702197142747:kds-consumer-dlq",
      "Sid": "HttpsOnly"
    }
  ],
  "Version": "2012-10-17"
}
POLICY

  receive_wait_time_seconds  = 0
  visibility_timeout_seconds = 30
}
