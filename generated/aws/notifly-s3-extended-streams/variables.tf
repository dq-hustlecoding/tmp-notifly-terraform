variable "kds" {
  description = "AWS Kinesis Data Stream for client event processing."
  type        = map(any)
  default = {
    arn  = "arn:aws:kinesis:ap-northeast-2:702197142747:stream/notifly-pfavx6b9-streaming-data-solution-KdsDataStream4BCE778D-DL4D01KCd4cE"
    name = "notifly-pfavx6b9-streaming-data-solution-KdsDataStream4BCE778D-DL4D01KCd4cE"
  }
}

variable "aws_account_id" {
  description = "AWS Kinesis Data Stream for client event processing."
  type        = string
  default     = "702197142747"
}

variable "vpc_configurations" {
  description = "Values for vpc configurations"
  type        = map(any)
  default = {
    "subnet_ids"         = ["subnet-0d8d973861758eec4", "subnet-088e43d019b2ab0fe", "subnet-007edcbae215f8966"]
    "security_group_ids" = ["sg-0e9c443eb470da6af"]
  }
}

variable "rds_username" {
  description = "Database administrator username"
  type        = string
  sensitive   = true
}

variable "rds_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}

variable "lambdas" {
  description = "Map containing k-v paires that define the target lambdas to be created."
  type        = map(any)
  default = {
    "notifly-event-transformer" = {
      "name"        = "notifly-event-transformer"
      "description" = "Transforms raw events before storing them in the data lake"
      "entrypoint"  = "index.transformRawEvents"
      "s3_bucket"   = "notifly-lambda-builds"
      "s3_key"      = "notifly-event-transformer.zip"
    }
    "notifly-message-event-transformer" = {
      "name"        = "notifly-message-event-transformer"
      "description" = "Transforms message events before storing them in the data lake"
      "entrypoint"  = "index.transformMessageEvents"
      "s3_bucket"   = "notifly-lambda-builds"
      "s3_key"      = "notifly-event-transformer.zip"
    }
    "notifly-triggering-event-transformer" = {
      "name"        = "notifly-triggering-event-transformer"
      "description" = "Transforms triggering events before storing them in the data lake"
      "entrypoint"  = "index.transformTriggeringEvents"
      "s3_bucket"   = "notifly-lambda-builds"
      "s3_key"      = "notifly-event-transformer.zip"
    }
    "notifly-analytics-partition-generator" = {
      "name"        = "notifly-analytics-partition-generator"
      "description" = "Generates partition keys for analytics"
      "entrypoint"  = "index.handler"
      "s3_bucket"   = "notifly-lambda-builds"
      "s3_key"      = "notifly-analytics-partition-generator.zip"
    }
  }
}
