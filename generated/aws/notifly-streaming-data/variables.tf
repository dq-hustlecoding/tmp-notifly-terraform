variable "kds" {
  description = "AWS Kinesis Data Stream for client event processing."
  type        = map(any)
  default = {
    arn              = "arn:aws:kinesis:ap-northeast-2:702197142747:stream/notifly-pfavx6b9-streaming-data-solution-KdsDataStream4BCE778D-DL4D01KCd4cE"
    name             = "notifly-pfavx6b9-streaming-data-solution-KdsDataStream4BCE778D-DL4D01KCd4cE"
    retention_period = 24
    shard_count      = 8
  }
}

variable "kds_consumer" {
  description = "Kinesis Data Stream consumer"
  type        = map(any)
  default = {
    name         = "kds-consumer"
    description  = "Kinesis Data Stream consumer"
    handler      = "index.handler"
    package_type = "Zip"
    memory_size  = 5312
    timeout      = 300
    s3_bucket    = "notifly-lambda-builds"
    s3_key       = "kds-consumer.zip"
    runtime      = "nodejs18.x"
  }
}

variable "api_stage_names" {
  description = "API Gateway stage names"
  type        = map(any)
  default = {
    prod = "prod"
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

variable "vpc_configurations" {
  description = "values for vpc configurations"
  type        = map(any)
  default = {
    "subnet_ids"         = ["subnet-0d8d973861758eec4", "subnet-088e43d019b2ab0fe", "subnet-007edcbae215f8966"]
    "security_group_ids" = ["sg-0e9c443eb470da6af"]
  }
}
