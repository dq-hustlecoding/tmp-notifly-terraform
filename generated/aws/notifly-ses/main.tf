data "aws_kinesis_firehose_delivery_stream" "ses_message_event_stream" {
  name = "firehose-ses-message-events"
}

resource "aws_kinesis_firehose_delivery_stream" "ses_stream" {
  name        = "notifly-ses"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.bucket.arn

    prefix              = "data/dt=!{timestamp:yyyy'-'MM'-'dd}/h=!{timestamp:HH}/"
    error_output_prefix = "errors/!{firehose:error-output-type}/dt=!{timestamp:yyyy'-'MM'-'dd}/h=!{timestamp:HH}/"

    buffer_size = 5
  }
}

resource "aws_iam_role" "firehose_role" {
  name = "firehose_role_for_ses"

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

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]

    effect = "Allow"

    resources = [
      "${aws_s3_bucket.bucket.arn}/*",
      aws_s3_bucket.bucket.arn
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.firehose_role.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

resource "aws_s3_bucket" "bucket" {
  bucket = "ses-events-notifly-pfavx6b9"
}

resource "aws_ses_configuration_set" "notifly" {
  name = "notifly"
  reputation_metrics_enabled = true
}

resource "aws_ses_event_destination" "firehose_destination" {
  name                   = "notifly-ses-events-firehose"
  configuration_set_name = aws_ses_configuration_set.notifly.name

  enabled = true
  matching_types = [
    "bounce",
    "send",
    "reject",
    "complaint",
    "delivery",
    "open",
    "click",
    "renderingFailure",
  ]

  kinesis_destination {
    role_arn   = aws_iam_role.ses_role.arn
    stream_arn = aws_kinesis_firehose_delivery_stream.ses_stream.arn
  }
}

resource "aws_ses_event_destination" "message_events_destination" {
  name                   = "notifly-message-events-firehose"
  configuration_set_name = aws_ses_configuration_set.notifly.name

  enabled = true
  matching_types = [
    "bounce",
    "send",
    "reject",
    "complaint",
    "delivery",
    "open",
    "click",
    "renderingFailure",
  ]

  kinesis_destination {
    role_arn   = aws_iam_role.ses_role.arn
    stream_arn = data.aws_kinesis_firehose_delivery_stream.ses_message_event_stream.arn
  }
}

resource "aws_ses_event_destination" "cloudwatch_destination" {
  name                   = "notifly-ses-events"
  configuration_set_name = aws_ses_configuration_set.notifly.name

  enabled = true
  matching_types = [
    "bounce",
    "send",
    "reject",
    "complaint",
    "delivery",
    "open",
    "click",
    "renderingFailure",
  ]

  cloudwatch_destination {
    default_value  = "notifly"
    dimension_name = "ses:configuration-set"
    value_source   = "messageTag"
  }
}

resource "aws_iam_role" "ses_role" {
  name = "ses_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ses.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ses_role_policy" {
  name = "ses_role_policy"
  role = aws_iam_role.ses_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch",
        ]
        Effect = "Allow"
        Resource = [
          "${aws_kinesis_firehose_delivery_stream.ses_stream.arn}",
          "${data.aws_kinesis_firehose_delivery_stream.ses_message_event_stream.arn}"
        ]
      }
    ]
  })
}
