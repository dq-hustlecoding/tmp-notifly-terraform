locals {
  use_existing_route53_zone = true
  domain                    = "api.notifly.tech"

  # Removing trailing dot from domain - just to be sure :)
  domain_name = trimsuffix(local.domain, ".")

  zone_id = try(data.aws_route53_zone.this[0].zone_id, aws_route53_zone.this[0].zone_id)
}

module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "3.1.1"

  name          = "notifly-http"
  description   = "Notifly HTTP API Gateway"
  protocol_type = "HTTP"

  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent", "x-notifly-sdk-version", "x-notifly-sdk-Wrapper"]
    allow_methods = ["*"]
    allow_origins = ["*"]
    max_age       = 600 # 10 minutes
  }

  domain_name                 = local.domain_name
  domain_name_certificate_arn = data.aws_acm_certificate.notifly.arn

  # Access logs
  default_stage_access_log_destination_arn = aws_cloudwatch_log_group.notifly_api_logs.arn
  default_stage_access_log_format          = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.path $context.protocol\" \"$context.routeKey\" $context.status $context.responseLength $context.requestId $context.integrationErrorMessage"

  default_route_settings = {
    detailed_metrics_enabled = true
    throttling_burst_limit   = 5000
    throttling_rate_limit    = 5000
  }

  # Routes and integrations
  integrations = {
    // For CORS preflight
    "OPTIONS /{proxy+}" = {
      lambda_arn             = module.aws_lambda["notifly-api"].lambda_function_arn
      payload_format_version = "2.0"
    }

    "POST /" = {
      lambda_arn             = module.aws_lambda["notifly-api"].lambda_function_arn
      payload_format_version = "2.0"
      timeout_milliseconds   = 12000
    }

    "ANY /campaign/{projectId}/{campaignId}/{op}" = {
      lambda_arn             = module.aws_lambda["notifly-campaign-api"].lambda_function_arn
      payload_format_version = "2.0"
    }

    "OPTIONS /user-state/{projectId}/{userId}" = {
      lambda_arn             = module.aws_lambda["notifly-user-state-api"].lambda_function_arn
      payload_format_version = "2.0"
    }

    "GET /user-state/{projectId}/{userId}" = {
      lambda_arn             = module.aws_lambda["notifly-user-state-api"].lambda_function_arn
      payload_format_version = "2.0"
    }

    "POST /payment/{path+}" = {
      lambda_arn             = module.aws_lambda["notifly-payment-api"].lambda_function_arn
      payload_format_version = "2.0"
      authorization_type     = "JWT"
      authorizer_id          = aws_apigatewayv2_authorizer.payment_api_authorizer.id
    }

    "POST /webhook/payment" = {
      lambda_arn = module.aws_lambda["payment-webhook-receiver"].lambda_function_arn
    }

    "POST /webhook/cafe24" = {
      lambda_arn = module.aws_lambda["cafe24-webhook-receiver"].lambda_function_arn
    }

    "POST /cache/invalidate" = {
      lambda_arn             = module.aws_lambda["notifly-redis-manager-api"].lambda_function_arn
      payload_format_version = "2.0"
      authorization_type     = "JWT"
      authorizer_id          = aws_apigatewayv2_authorizer.notifly_web_proxy_api_authorizer.id
    }

    "$default" = {
      lambda_arn = module.aws_lambda["notifly-api"].lambda_function_arn
    }
  }

  body = templatefile("api.yaml", {
    notifly_api_lambda_function_arn = module.aws_lambda["notifly-api"].lambda_function_arn
  })

  tags = {
    Name = "notifly-http-apigateway"
  }
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

  timeout     = each.value.timeout
  memory_size = each.value.memory_size
  publish     = true

  environment_variables = {
    RDS_DATABASE                   = "postgres"
    RDS_HOSTNAME                   = "notifly-rds-proxy.proxy-cwvdx2o498bl.ap-northeast-2.rds.amazonaws.com"
    RDS_RW_HOSTNAME                = "notifly-rds-proxy.proxy-cwvdx2o498bl.ap-northeast-2.rds.amazonaws.com"
    RDS_RO_HOSTNAME                = "notifly-rds-proxy.proxy-cwvdx2o498bl.ap-northeast-2.rds.amazonaws.com"
    RDS_USERNAME                   = var.rds_username
    RDS_PASSWORD                   = var.rds_password
    NODE_NO_WARNINGS               = "1"
    PORTONE_API_KEY                = "0101215005813140"
    PORTONE_API_SECRET             = "MdgRTv3e8BBb8hAlfs8nR9ucOlaEAyld5yHVONiYxf0gEdVSmcmWYw2anLRweHeVnRPH7N8qk3LcN6p4"
    CAFE24_X_API_KEY               = "008ca146-b3c7-445d-9e65-9ad6b7f8f6f2"
    SQS_PUSH_QUEUE_URL             = "https://sqs.ap-northeast-2.amazonaws.com/702197142747/scheduled-batch-push-notification-queue"
    SQS_KAKAO_ALIMTALK_QUEUE_URL   = "https://sqs.ap-northeast-2.amazonaws.com/702197142747/scheduled-batch-kakao-alimtalk-queue"
    SQS_KAKAO_FRIENDTALK_QUEUE_URL = "https://sqs.ap-northeast-2.amazonaws.com/702197142747/scheduled-batch-kakao-friendtalk-queue"
    SQS_TEXT_MESSAGE_QUEUE_URL     = "https://sqs.ap-northeast-2.amazonaws.com/702197142747/scheduled-batch-text-message-queue"
    SQS_EMAIL_QUEUE_URL            = "https://sqs.ap-northeast-2.amazonaws.com/702197142747/email-delivery-queue"
    SQS_WEB_PUSH_QUEUE_URL         = "https://sqs.ap-northeast-2.amazonaws.com/702197142747/web-push-delivery-queue"
    SQS_WEBHOOK_QUEUE_URL          = "https://sqs.ap-northeast-2.amazonaws.com/702197142747/webhook-delivery-queue"
    SQS_CAFE24_WORKER_QUEUE_URL    = "https://sqs.ap-northeast-2.amazonaws.com/702197142747/cafe24-worker-queue"
    CAFE24_CLIENT_ID               = "hdbI2jCsIR5thYPKwiHlCB"
    CAFE24_CLIENT_SECRET           = "uVHVdpyeeEG1SVXqs3nYQO"
    REDIS_HOST                     = "clustercfg.notifly-cache.bcshxz.apn2.cache.amazonaws.com"
    NOTIFLY_PG_PROXY_API_SECRET    = "Wa+LSckC5pYaL3LD6L6J+FK9OWNnTQ4iD/xMuk4OwwI="
  }

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.apigatewayv2_api_execution_arn}/*/*"
    }
  }

  attach_policy_statements = true
  policy_statements = {
    dynamodb = {
      effect    = "Allow",
      actions   = ["dynamodb:*"],
      resources = ["arn:aws:dynamodb:ap-northeast-2:702197142747:table/*"]
    },
    sqs = {
      effect    = "Allow",
      actions   = ["sqs:SendMessage"],
      resources = ["*"]
    },
    kinesis = {
      effect    = "Allow",
      actions   = ["kinesis:PutRecord", "kinesis:PutRecords"],
      resources = ["*"]
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

resource "aws_cloudwatch_log_group" "notifly_api_logs" {
  name = "notifly-api-logs"
}

#############################
# AWS API Gateway Authorizer
#############################

resource "aws_apigatewayv2_authorizer" "api_authorizer" {
  api_id           = module.api_gateway.apigatewayv2_api_id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "notiflyApiAuthorizer"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.user_pool_client.id] # App client id
    issuer   = "https://${aws_cognito_user_pool.user_pool.endpoint}"
  }
}

resource "aws_apigatewayv2_authorizer" "payment_api_authorizer" {
  api_id           = module.api_gateway.apigatewayv2_api_id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "notiflyPaymentApiAuthorizer"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.payment_user_pool_client.id] # App client id
    issuer   = "https://${aws_cognito_user_pool.payment_user_pool.endpoint}"
  }
}

resource "aws_apigatewayv2_authorizer" "notifly_web_proxy_api_authorizer" {
  api_id           = module.api_gateway.apigatewayv2_api_id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "notiflyWebProxyApiAuthorizer"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.web_user_pool_client.id] # App client id
    issuer   = "https://${aws_cognito_user_pool.web_user_pool.endpoint}"
  }
}

########################
# AWS Cognito User Pool
########################

resource "aws_cognito_user_pool" "user_pool" {
  name = "ApiUserPool7811AFAD-loZpbIY7ecbB"

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name         = "notifly"
  user_pool_id = aws_cognito_user_pool.user_pool.id

  // Token validates
  refresh_token_validity = 30
  access_token_validity  = 1
  id_token_validity      = 1

  token_validity_units {
    refresh_token = "days"
    access_token  = "hours"
    id_token      = "hours"
  }

  explicit_auth_flows           = ["ALLOW_ADMIN_USER_PASSWORD_AUTH", "ALLOW_CUSTOM_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_PASSWORD_AUTH", "ALLOW_USER_SRP_AUTH"]
  enable_token_revocation       = true
  prevent_user_existence_errors = "ENABLED"
}

resource "aws_cognito_user_pool" "user_pool_dev" {
  name = "notifly-sdk-dev"

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_cognito_user_pool_client" "user_pool_dev_client" {
  name         = "notifly-sdk-dev"
  user_pool_id = aws_cognito_user_pool.user_pool_dev.id

  // Token validates
  refresh_token_validity = 30
  access_token_validity  = 1
  id_token_validity      = 1

  token_validity_units {
    refresh_token = "days"
    access_token  = "hours"
    id_token      = "hours"
  }

  explicit_auth_flows           = ["ALLOW_ADMIN_USER_PASSWORD_AUTH", "ALLOW_CUSTOM_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_PASSWORD_AUTH", "ALLOW_USER_SRP_AUTH"]
  enable_token_revocation       = true
  prevent_user_existence_errors = "ENABLED"
}

resource "aws_cognito_user_pool" "web_user_pool" {
  name = "notifly"

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_cognito_user_pool_client" "web_user_pool_client" {
  name         = "notifly-app"
  user_pool_id = aws_cognito_user_pool.web_user_pool.id

  // Token validates
  refresh_token_validity = 30
  access_token_validity  = 1
  id_token_validity      = 1

  token_validity_units {
    refresh_token = "days"
    access_token  = "days"
    id_token      = "days"
  }

  explicit_auth_flows           = ["ALLOW_ADMIN_USER_PASSWORD_AUTH", "ALLOW_CUSTOM_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_PASSWORD_AUTH", "ALLOW_USER_SRP_AUTH"]
  enable_token_revocation       = true
  prevent_user_existence_errors = "ENABLED"
}

resource "aws_cognito_user_pool" "web_user_pool_dev" {
  name = "notifly-dev"

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_cognito_user_pool_client" "web_user_pool_dev_client" {
  name         = "notifly-app-dev"
  user_pool_id = aws_cognito_user_pool.web_user_pool_dev.id

  // Token validates
  refresh_token_validity = 30
  access_token_validity  = 1
  id_token_validity      = 1

  token_validity_units {
    refresh_token = "days"
    access_token  = "days"
    id_token      = "days"
  }

  explicit_auth_flows           = ["ALLOW_ADMIN_USER_PASSWORD_AUTH", "ALLOW_CUSTOM_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_PASSWORD_AUTH", "ALLOW_USER_SRP_AUTH"]
  enable_token_revocation       = true
  prevent_user_existence_errors = "ENABLED"
}

resource "aws_cognito_user_pool" "api_user_pool" {
  name = "notifly-api"

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_cognito_user_pool_client" "api_user_pool_client" {
  name         = "notifly-api"
  user_pool_id = aws_cognito_user_pool.api_user_pool.id

  // Token validates
  refresh_token_validity = 30
  access_token_validity  = 1
  id_token_validity      = 1

  token_validity_units {
    refresh_token = "days"
    access_token  = "hours"
    id_token      = "hours"
  }

  explicit_auth_flows           = ["ALLOW_ADMIN_USER_PASSWORD_AUTH", "ALLOW_CUSTOM_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_PASSWORD_AUTH", "ALLOW_USER_SRP_AUTH"]
  enable_token_revocation       = true
  prevent_user_existence_errors = "ENABLED"
}

resource "aws_cognito_user_pool" "api_user_pool_dev" {
  name = "notifly-api-dev"

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_cognito_user_pool_client" "api_user_pool_dev_client" {
  name         = "notifly-api-dev"
  user_pool_id = aws_cognito_user_pool.api_user_pool_dev.id

  // Token validates
  refresh_token_validity = 30
  access_token_validity  = 1
  id_token_validity      = 1

  token_validity_units {
    refresh_token = "days"
    access_token  = "hours"
    id_token      = "hours"
  }

  explicit_auth_flows           = ["ALLOW_ADMIN_USER_PASSWORD_AUTH", "ALLOW_CUSTOM_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_PASSWORD_AUTH", "ALLOW_USER_SRP_AUTH"]
  enable_token_revocation       = true
  prevent_user_existence_errors = "ENABLED"
}

resource "aws_cognito_user_pool" "payment_user_pool" {
  name = "notifly-payment"

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_cognito_user_pool_client" "payment_user_pool_client" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.payment_user_pool.id

  // Token validates
  refresh_token_validity = 60
  access_token_validity  = 5
  id_token_validity      = 5

  token_validity_units {
    refresh_token = "minutes"
    access_token  = "minutes"
    id_token      = "minutes"
  }

  generate_secret = true

  explicit_auth_flows     = ["ALLOW_ADMIN_USER_PASSWORD_AUTH", "ALLOW_CUSTOM_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_PASSWORD_AUTH", "ALLOW_USER_SRP_AUTH"]
  enable_token_revocation = true
}

########################
# Custom domain
########################

data "aws_route53_zone" "this" {
  count = local.use_existing_route53_zone ? 1 : 0

  name         = "notifly.tech"
  private_zone = false
}

resource "aws_route53_zone" "this" {
  count = !local.use_existing_route53_zone ? 1 : 0

  name = local.domain_name
}

resource "aws_route53_record" "api" {
  allow_overwrite = false
  zone_id         = local.zone_id
  name            = local.domain_name
  type            = "CNAME"
  ttl             = 60

  records = ["${module.api_gateway.apigatewayv2_domain_name_configuration[0].target_domain_name}."]
}

data "aws_acm_certificate" "notifly" {
  domain   = "notifly.tech"
  statuses = ["ISSUED"]
}
