variable "lambdas" {
  description = "Map containing k-v paires that define the target lambdas to be created."
  type        = map(any)
  default = {
    "notifly-api" = {
      "name"              = "notifly-api"
      "description"       = "Lambda function for notifly API proxy."
      "handler_file_name" = "index"
      "source_path_file"  = "index.js"
      "memory_size"       = 512
      "timeout"           = 60
    }
    "notifly-campaign-api" = {
      "name"              = "notifly-campaign-api"
      "description"       = "Lambda function for triggering campaign."
      "handler_file_name" = "index"
      "source_path_file"  = "index.js"
      "memory_size"       = 512
      "timeout"           = 30
    }
    "notifly-user-state-api" = {
      "name"              = "notifly-user-state-api"
      "description"       = "Lambda function retrieving user state."
      "handler_file_name" = "index"
      "source_path_file"  = "index.js"
      "memory_size"       = 2048
      "timeout"           = 120
    }
    "payment-webhook-receiver" = {
      "name"              = "payment-webhook-receiver"
      "description"       = "Lambda function for receiving webhook from payment provider"
      "handler_file_name" = "index"
      "source_path_file"  = "index.js"
      "memory_size"       = 256
      "timeout"           = 30
    }
    "cafe24-webhook-receiver" = {
      "name"              = "cafe24-webhook-receiver"
      "description"       = "Lambda function for receiving webhook from cafe24"
      "handler_file_name" = "index"
      "source_path_file"  = "index.js"
      "memory_size"       = 512
      "timeout"           = 30
    }
    "notifly-payment-api" = {
      "name"              = "notifly-payment-api"
      "description"       = "Lambda function for executing payment"
      "handler_file_name" = "index"
      "source_path_file"  = "index.js"
      "memory_size"       = 512
      "timeout"           = 30
    }
    "notifly-redis-manager-api" = {
      "name"              = "notifly-redis-manager-api"
      "description"       = "Lambda function for notifly redis cache managing"
      "handler_file_name" = "index"
      "source_path_file"  = "index.js"
      "memory_size"       = 512
      "timeout"           = 30
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
