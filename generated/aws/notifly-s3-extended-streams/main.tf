data "aws_glue_catalog_table" "event_logs_catalog_table" {
  name          = "notifly_event_logs"
  database_name = "notifly_analytics"
}

data "aws_glue_catalog_table" "message_events_catalog_table" {
  name          = "notifly_message_events"
  database_name = "notifly_analytics"
}

data "aws_glue_catalog_table" "triggering_events_catalog_table" {
  name          = "notifly_triggering_events"
  database_name = "notifly_analytics"
}

data "aws_glue_catalog_table" "experiment_intermediate_results_catalog_table" {
  name          = "notifly_experiment_intermediate_results"
  database_name = "notifly_analytics"
}

/* ========================================= S3 Buckets ============================================ */

resource "aws_s3_bucket" "raw_events_bucket" {
  bucket = "raw-events-notifly-pfavx6b9"
}

resource "aws_s3_bucket" "notifly_event_logs_bucket" {
  bucket = "notifly-event-logs"
}

resource "aws_s3_bucket" "notifly_message_events_bucket" {
  bucket = "notifly-message-events"
}

resource "aws_s3_bucket" "notifly_triggering_events_bucket" {
  bucket = "notifly-triggering-events"
}

resource "aws_s3_bucket" "notifly_experiment_intermediate_results_bucket" {
  bucket = "notifly-experiment-intermediate-results"
}

resource "aws_s3_bucket_acl" "raw_events_bucket_acl" {
  expected_bucket_owner = var.aws_account_id
  bucket                = aws_s3_bucket.raw_events_bucket.id
  acl                   = "private"
}

/* ========================================= S3 Buckets Notification ============================================ */

resource "aws_lambda_permission" "allow_event_logs_bucket_notification" {
  statement_id  = "AllowExecutionFromEventLogsBucket"
  action        = "lambda:InvokeFunction"
  function_name = module.aws_lambda["notifly-analytics-partition-generator"].lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.notifly_event_logs_bucket.arn
}

resource "aws_lambda_permission" "allow_message_events_bucket_notification" {
  statement_id  = "AllowExecutionFromMessageEventsBucket"
  action        = "lambda:InvokeFunction"
  function_name = module.aws_lambda["notifly-analytics-partition-generator"].lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.notifly_message_events_bucket.arn
}

resource "aws_lambda_permission" "allow_triggering_events_bucket_notification" {
  statement_id  = "AllowExecutionFromTriggeringEventsBucket"
  action        = "lambda:InvokeFunction"
  function_name = module.aws_lambda["notifly-analytics-partition-generator"].lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.notifly_triggering_events_bucket.arn
}

resource "aws_lambda_permission" "allow_experiment_intermediate_results_bucket_notification" {
  statement_id  = "AllowExecutionFromExperimentIntermediateResultsBucket"
  action        = "lambda:InvokeFunction"
  function_name = module.aws_lambda["notifly-analytics-partition-generator"].lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.notifly_experiment_intermediate_results_bucket.arn
}

resource "aws_s3_bucket_notification" "bucket_notification_for_event_logs" {
  bucket = aws_s3_bucket.notifly_event_logs_bucket.id

  lambda_function {
    lambda_function_arn = module.aws_lambda["notifly-analytics-partition-generator"].lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "data/"
    filter_suffix       = ".parquet"
  }

  depends_on = [aws_lambda_permission.allow_event_logs_bucket_notification]
}

resource "aws_s3_bucket_notification" "bucket_notification_for_message_events" {
  bucket = aws_s3_bucket.notifly_message_events_bucket.id

  lambda_function {
    lambda_function_arn = module.aws_lambda["notifly-analytics-partition-generator"].lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "data/"
    filter_suffix       = ".parquet"
  }

  depends_on = [aws_lambda_permission.allow_message_events_bucket_notification]
}

resource "aws_s3_bucket_notification" "bucket_notification_for_triggering_events" {
  bucket = aws_s3_bucket.notifly_triggering_events_bucket.id

  lambda_function {
    lambda_function_arn = module.aws_lambda["notifly-analytics-partition-generator"].lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "data/"
    filter_suffix       = ".parquet"
  }

  depends_on = [aws_lambda_permission.allow_triggering_events_bucket_notification]
}

resource "aws_s3_bucket_notification" "bucket_notification_for_experiment_intermediate_results" {
  bucket = aws_s3_bucket.notifly_experiment_intermediate_results_bucket.id

  lambda_function {
    lambda_function_arn = module.aws_lambda["notifly-analytics-partition-generator"].lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "data/"
    filter_suffix       = ".parquet"
  }

  depends_on = [aws_lambda_permission.allow_experiment_intermediate_results_bucket_notification]
}

/* ======================================= Kinesis data streams ========================================== */

data "aws_kinesis_stream" "message-events-stream" {
  name = "notifly-message-events-stream"
}

data "aws_kinesis_stream" "triggering-events-stream" {
  name = "notifly-triggering-events-stream"
}

/* ========================================= Lambda functions ============================================ */

module "aws_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 2.0"

  for_each = var.lambdas

  function_name  = each.value.name
  description    = each.value.description
  handler        = each.value.entrypoint
  architectures  = ["arm64"]
  runtime        = "nodejs18.x"
  create_package = false

  s3_existing_package = {
    bucket = each.value.s3_bucket
    key    = each.value.s3_key
  }

  attach_network_policy  = true
  vpc_subnet_ids         = var.vpc_configurations.subnet_ids
  vpc_security_group_ids = var.vpc_configurations.security_group_ids

  memory_size = 128
  timeout     = 60
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
  policy_statements = each.value.name == "notifly-analytics-partition-generator" ? {
    glue = {
      effect    = "Allow",
      actions   = ["glue:*"],
      resources = ["*"],
    },
    } : {
    dynamodb = {
      effect    = "Allow",
      actions   = ["dynamodb:*"],
      resources = ["*"],
    },
  }
}

/* ========================================= Firehose Delivery Stream ============================================ */

resource "aws_iam_role" "firehose_role" {
  name = "firehose_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "firehose_policy" {
  name = "firehose_policy"
  role = aws_iam_role.firehose_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
            "kinesis:DescribeStream",
            "kinesis:GetShardIterator",
            "kinesis:GetRecords",
            "kinesis:ListShards"
        ],
        "Resource": [
            "${var.kds.arn}",
            "${data.aws_kinesis_stream.message-events-stream.arn}",
            "${data.aws_kinesis_stream.triggering-events-stream.arn}"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
            "s3:AbortMultipartUpload",
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads",
            "s3:PutObject"
        ],
        "Resource": [
            "${aws_s3_bucket.raw_events_bucket.arn}",
            "${aws_s3_bucket.raw_events_bucket.arn}/*",
            "${aws_s3_bucket.notifly_event_logs_bucket.arn}",
            "${aws_s3_bucket.notifly_event_logs_bucket.arn}/*",
            "${aws_s3_bucket.notifly_message_events_bucket.arn}",
            "${aws_s3_bucket.notifly_message_events_bucket.arn}/*",
            "${aws_s3_bucket.notifly_triggering_events_bucket.arn}",
            "${aws_s3_bucket.notifly_triggering_events_bucket.arn}/*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
            "glue:GetTableVersions"
        ],
        "Resource": [
            "*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
            "lambda:InvokeFunction"
        ],
        "Resource": [
            "${module.aws_lambda["notifly-event-transformer"].lambda_function_arn}",
            "${module.aws_lambda["notifly-message-event-transformer"].lambda_function_arn}",
            "${module.aws_lambda["notifly-triggering-event-transformer"].lambda_function_arn}"
        ]
      }
  ]
}
EOF
}

resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
  name        = "terraform-kinesis-firehose-extended-s3-stream"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = var.kds.arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.raw_events_bucket.arn

    # Example prefix using partitionKeyFromQuery, applicable to JQ processor
    prefix              = "data/project_id=!{partitionKeyFromQuery:project_id}/dt=!{timestamp:yyyy'-'MM'-'dd}/h=!{timestamp:HH}/"
    error_output_prefix = "errors/!{firehose:error-output-type}/dt=!{timestamp:yyyy'-'MM'-'dd}/h=!{timestamp:HH}/"

    dynamic_partitioning_configuration {
      enabled        = true
      retry_duration = 300
    }

    # https://docs.aws.amazon.com/firehose/latest/dev/dynamic-partitioning.html
    buffer_size = 64

    processing_configuration {
      enabled = true

      # Multi-record deaggregation processor example
      processors {
        type = "RecordDeAggregation"
        parameters {
          parameter_name  = "SubRecordType"
          parameter_value = "JSON"
        }
      }

      # New line delimiter processor example
      processors {
        type = "AppendDelimiterToRecord"
      }

      # JQ processor example
      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{project_id:.project_id}"
        }
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
      }
    }
  }
}

resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream_for_notifly_event_logs" {
  name        = "firehose-notifly-event-logs"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = var.kds.arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.notifly_event_logs_bucket.arn

    prefix              = "data/project_id=!{partitionKeyFromQuery:project_id}/dt=!{partitionKeyFromQuery:dt}/h=!{partitionKeyFromQuery:h}/pre_conversion=!{partitionKeyFromQuery:pre_conversion}/"
    error_output_prefix = "errors/!{firehose:error-output-type}/dt=!{timestamp:yyyy'-'MM'-'dd}/h=!{timestamp:HH}/"

    dynamic_partitioning_configuration {
      enabled        = true
      retry_duration = 60
    }

    data_format_conversion_configuration {
      enabled = true
      input_format_configuration {
        deserializer {
          open_x_json_ser_de {
            case_insensitive = false
          }
        }
      }
      output_format_configuration {
        serializer {
          parquet_ser_de {
            enable_dictionary_compression = true
          }
        }
      }
      schema_configuration {
        database_name = data.aws_glue_catalog_table.event_logs_catalog_table.database_name
        table_name    = data.aws_glue_catalog_table.event_logs_catalog_table.name
        role_arn      = aws_iam_role.firehose_role.arn
      }
    }

    # https://docs.aws.amazon.com/firehose/latest/dev/dynamic-partitioning.html
    buffer_size     = 64
    buffer_interval = 60
    processing_configuration {
      enabled = true

      # Lambda
      processors {
        type = "Lambda"
        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = module.aws_lambda["notifly-event-transformer"].lambda_function_arn
        }
        parameters {
          parameter_name  = "BufferSizeInMBs"
          parameter_value = "3"
        }
        parameters {
          parameter_name  = "BufferIntervalInSeconds"
          parameter_value = "60"
        }
      }

      # Multi-record deaggregation processor
      processors {
        type = "RecordDeAggregation"
        parameters {
          parameter_name  = "SubRecordType"
          parameter_value = "JSON"
        }
      }

      # New line delimiter processor
      processors {
        type = "AppendDelimiterToRecord"
      }

      # JQ processor
      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{project_id:.project_id, dt:.dt, h:.h, pre_conversion:.pre_conversion}"
        }
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
      }
    }
  }
}

resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream_for_notifly_message_events" {
  name        = "firehose-notifly-message-events"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = data.aws_kinesis_stream.message-events-stream.arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.notifly_message_events_bucket.arn

    prefix              = "data/project_id=!{partitionKeyFromQuery:project_id}/campaign_id=!{partitionKeyFromQuery:campaign_id}/dt=!{partitionKeyFromQuery:dt}/h=!{partitionKeyFromQuery:h}/pre_conversion=!{partitionKeyFromQuery:pre_conversion}/"
    error_output_prefix = "errors/!{firehose:error-output-type}/dt=!{timestamp:yyyy'-'MM'-'dd}/h=!{timestamp:HH}/"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "/aws/kinesisfirehose/firehose-notifly-message-events"
      log_stream_name = "DestinationDelivery"
    }

    dynamic_partitioning_configuration {
      enabled        = true
      retry_duration = 300
    }

    data_format_conversion_configuration {
      enabled = true
      input_format_configuration {
        deserializer {
          open_x_json_ser_de {
            case_insensitive = false
          }
        }
      }
      output_format_configuration {
        serializer {
          parquet_ser_de {
            enable_dictionary_compression = true
          }
        }
      }
      schema_configuration {
        database_name = data.aws_glue_catalog_table.message_events_catalog_table.database_name
        table_name    = data.aws_glue_catalog_table.message_events_catalog_table.name
        role_arn      = aws_iam_role.firehose_role.arn
      }
    }

    buffer_size = 64

    processing_configuration {
      enabled = true

      # Lambda
      processors {
        type = "Lambda"
        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = module.aws_lambda["notifly-message-event-transformer"].lambda_function_arn
        }
        parameters {
          parameter_name  = "BufferSizeInMBs"
          parameter_value = "3"
        }
        parameters {
          parameter_name  = "BufferIntervalInSeconds"
          parameter_value = "60"
        }
      }

      # Multi-record deaggregation processor
      processors {
        type = "RecordDeAggregation"
        parameters {
          parameter_name  = "SubRecordType"
          parameter_value = "JSON"
        }
      }

      # New line delimiter processor
      processors {
        type = "AppendDelimiterToRecord"
      }

      # JQ processor
      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{project_id:.project_id, campaign_id:.campaign_id, dt:.dt, h:.h, pre_conversion:.pre_conversion}"
        }
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
      }
    }
  }
}

resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream_for_notifly_ses_message_events" {
  name        = "firehose-ses-message-events"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.notifly_message_events_bucket.arn

    prefix              = "data/project_id=!{partitionKeyFromQuery:project_id}/campaign_id=!{partitionKeyFromQuery:campaign_id}/dt=!{partitionKeyFromQuery:dt}/h=!{partitionKeyFromQuery:h}/pre_conversion=!{partitionKeyFromQuery:pre_conversion}/"
    error_output_prefix = "errors/!{firehose:error-output-type}/dt=!{timestamp:yyyy'-'MM'-'dd}/h=!{timestamp:HH}/"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "/aws/kinesisfirehose/firehose-notifly-ses-message-events"
      log_stream_name = "DestinationDelivery"
    }

    dynamic_partitioning_configuration {
      enabled        = true
      retry_duration = 300
    }

    data_format_conversion_configuration {
      enabled = true
      input_format_configuration {
        deserializer {
          open_x_json_ser_de {
            case_insensitive = false
          }
        }
      }
      output_format_configuration {
        serializer {
          parquet_ser_de {
            enable_dictionary_compression = true
          }
        }
      }
      schema_configuration {
        database_name = data.aws_glue_catalog_table.message_events_catalog_table.database_name
        table_name    = data.aws_glue_catalog_table.message_events_catalog_table.name
        role_arn      = aws_iam_role.firehose_role.arn
      }
    }

    buffer_size = 64

    processing_configuration {
      enabled = true

      # Lambda
      processors {
        type = "Lambda"
        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = module.aws_lambda["notifly-message-event-transformer"].lambda_function_arn
        }
        parameters {
          parameter_name  = "BufferSizeInMBs"
          parameter_value = "3"
        }
        parameters {
          parameter_name  = "BufferIntervalInSeconds"
          parameter_value = "60"
        }
      }

      # Multi-record deaggregation processor
      processors {
        type = "RecordDeAggregation"
        parameters {
          parameter_name  = "SubRecordType"
          parameter_value = "JSON"
        }
      }

      # New line delimiter processor
      processors {
        type = "AppendDelimiterToRecord"
      }

      # JQ processor
      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{project_id:.project_id, campaign_id:.campaign_id, dt:.dt, h:.h, pre_conversion:.pre_conversion}"
        }
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
      }
    }
  }
}

resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream_for_notifly_triggering_events" {
  name        = "firehose-notifly-triggering-events"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = data.aws_kinesis_stream.triggering-events-stream.arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.notifly_triggering_events_bucket.arn

    prefix              = "data/project_id=!{partitionKeyFromQuery:project_id}/campaign_id=!{partitionKeyFromQuery:campaign_id}/experiment_id=!{partitionKeyFromQuery:experiment_id}/dt=!{partitionKeyFromQuery:dt}/h=!{partitionKeyFromQuery:h}/"
    error_output_prefix = "errors/!{firehose:error-output-type}/dt=!{timestamp:yyyy'-'MM'-'dd}/h=!{timestamp:HH}/"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "/aws/kinesisfirehose/firehose-notifly-triggering-events"
      log_stream_name = "DestinationDelivery"
    }

    dynamic_partitioning_configuration {
      enabled        = true
      retry_duration = 300
    }

    data_format_conversion_configuration {
      enabled = true
      input_format_configuration {
        deserializer {
          open_x_json_ser_de {
            case_insensitive = false
          }
        }
      }
      output_format_configuration {
        serializer {
          parquet_ser_de {
            enable_dictionary_compression = true
          }
        }
      }
      schema_configuration {
        database_name = data.aws_glue_catalog_table.triggering_events_catalog_table.database_name
        table_name    = data.aws_glue_catalog_table.triggering_events_catalog_table.name
        role_arn      = aws_iam_role.firehose_role.arn
      }
    }

    buffer_size = 64

    processing_configuration {
      enabled = true

      # Lambda
      processors {
        type = "Lambda"
        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = module.aws_lambda["notifly-triggering-event-transformer"].lambda_function_arn
        }
        parameters {
          parameter_name  = "BufferSizeInMBs"
          parameter_value = "3"
        }
        parameters {
          parameter_name  = "BufferIntervalInSeconds"
          parameter_value = "60"
        }
      }

      # Multi-record deaggregation processor
      processors {
        type = "RecordDeAggregation"
        parameters {
          parameter_name  = "SubRecordType"
          parameter_value = "JSON"
        }
      }

      # New line delimiter processor
      processors {
        type = "AppendDelimiterToRecord"
      }

      # JQ processor
      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{project_id:.project_id, campaign_id:.campaign_id, experiment_id:.experiment_id, dt:.dt, h:.h}"
        }
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
      }
    }
  }
}
