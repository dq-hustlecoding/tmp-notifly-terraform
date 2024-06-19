variable "lambdas" {
  description = "Map containing k-v paires that define the target lambdas to be created."
  type        = map(any)
  default = {
    "external-event-consumer" = {
      "name"              = "external-event-consumer"
      "description"       = "Lambda function for notifly extennal event streaming."
      "handler_file_name" = "index"
      "source_path_file"  = "index.js"

    }
  }
}

variable "kds" {
  description = "Map containing k-v paires that define the target kinesis data stream to be created."
  type        = map(any)
  default = {
    arn  = "arn:aws:kinesis:ap-northeast-2:702197142747:stream/notifly-external-event-streaming"
    name = "notifly-external-event-streaming"
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
