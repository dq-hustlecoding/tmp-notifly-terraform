variable "lambdas" {
  description = "Map containing k-v paires that define the target lambdas to be created."
  type        = map(any)
  default = {
    "project-metadata-generator" = {
      "name"              = "project-metadata-generator"
      "description"       = "Lambda function for generating project metadata."
      "handler_file_name" = "index"
      "source_path_file"  = "index.js"
      "timeout"           = 900
    },
    "project-cleaner" = {
      "name"              = "project-cleaner"
      "description"       = "Lambda function for cleaning up finished campaigns"
      "handler_file_name" = "index"
      "source_path_file"  = "index.js"
      "timeout"           = 300
    }
    "event-table-partition-generator" = {
      "name"              = "event-table-partition-generator"
      "description"       = "Lambda function for generating partition in raw event table"
      "handler_file_name" = "index"
      "source_path_file"  = "index.js"
      "timeout"           = 900
    }
    "payment-executor" = {
      "name"              = "payment-executor"
      "description"       = "Lambda function for executing payments"
      "handler_file_name" = "index"
      "source_path_file"  = "index.js"
      "timeout"           = 300
    }
    "cafe24-token-refresher" = {
      "name"              = "cafe24-token-refresher"
      "description"       = "Lambda function for refreshing cafe24 token"
      "handler_file_name" = "index"
      "source_path_file"  = "index.js"
      "timeout"           = 300
    }
    "notifly-delivery-analysis-generator" = {
      "name"              = "notifly-delivery-analysis-generator"
      "description"       = "Lambda function for generating delivery analysis"
      "handler_file_name" = "index"
      "source_path_file"  = "index.js"
      "timeout"           = 300
    }
    "notifly-web-user-synchronizer" = { # This function is triggered by cognito user pool event
      "name"              = "notifly-web-user-synchronizer"
      "description"       = "Lambda function for synchronizing web user"
      "handler_file_name" = "index"
      "source_path_file"  = "index.js"
      "timeout"           = 300
    }
    "notifly-web-user-synchronizer-dev" = { # This function is triggered by cognito user pool event
      "name"              = "notifly-web-user-synchronizer-dev"
      "description"       = "Lambda function for synchronizing dev web user"
      "handler_file_name" = "index"
      "source_path_file"  = "index.js"
      "timeout"           = 300
    }
    "notifly-nhn-delivery-result-collector" = {
      "name"              = "notifly-nhn-delivery-result-collector"
      "description"       = "Lambda function for collecting delivery result from nhn"
      "handler_file_name" = "index"
      "source_path_file"  = "index.js"
      "timeout"           = 300
    }

    "anomaly-delivery-monitoring" = {
      "name"              = "anomaly-delivery-monitoring"
      "description"       = "Lambda function for monitoring delivery anomaly"
      "handler_file_name" = "index"
      "source_path_file"  = "index.js"
      "timeout"           = 300
    }
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
