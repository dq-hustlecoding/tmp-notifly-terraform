variable "lambdas" {
  description = "Map containing k-v paires that define the target lambdas to be created."
  type        = map(any)
  default = {
    scheduler = {
      "name"              = "scheduled-batch-scheduler"
      "zip_name"          = "scheduled-batch-scheduler"
      "description"       = "Scheduler Lambda function for scheduled batch message delivery"
      "handler_file_name" = "scheduler"
      "source_path_file"  = "scheduler.js"
      "timeout"           = 300
      "memory_size"       = 512
      "concurrency"       = -1
    }
    publisher = {
      "name"              = "scheduled-batch-publisher"
      "zip_name"          = "scheduled-batch-publisher"
      "description"       = "Publisher Lambda function for scheduled batch message delivery"
      "handler_file_name" = "publisher"
      "source_path_file"  = "publisher.js"
      "timeout"           = 300
      "memory_size"       = 10240
      "concurrency"       = -1
    }
    delivery = {
      "name"              = "scheduled-batch-delivery"
      "zip_name"          = "scheduled-batch-delivery"
      "description"       = "Delivery Lambda function for scheduled batch message delivery"
      "handler_file_name" = "delivery"
      "source_path_file"  = "delivery.js"
      "timeout"           = 300
      "memory_size"       = 512
      "concurrency"       = -1
    }
    event-triggered-message-scheduler = {
      "name"              = "event-triggered-message-scheduler"
      "zip_name"          = "event-triggered-message-scheduler"
      "description"       = "Event triggered message scheduler Lambda function for scheduled batch message delivery"
      "handler_file_name" = "index"
      "source_path_file"  = "index.js"
      "timeout"           = 300
      "memory_size"       = 10240
      "concurrency"       = 1
    }
    kakao_alimtalk_delivery = {
      "name"              = "scheduled-batch-kakao-alimtalk-delivery"
      "zip_name"          = "scheduled-batch-kakao-alimtalk-delivery"
      "description"       = "Delivery Lambda function for scheduled batch message delivery - kakao_alimtalk"
      "handler_file_name" = "kakao_alimtalk_delivery"
      "source_path_file"  = "kakao_alimtalk_delivery.js"
      "timeout"           = 300
      "memory_size"       = 512
      "concurrency"       = -1
    }
    kakao_friendtalk_delivery = {
      "name"              = "scheduled-batch-kakao-friendtalk-delivery"
      "zip_name"          = "scheduled-batch-kakao-friendtalk-delivery"
      "description"       = "Delivery Lambda function for scheduled batch message delivery - kakao_friendtalk"
      "handler_file_name" = "kakao_friendtalk_delivery"
      "source_path_file"  = "kakao_friendtalk_delivery.js"
      "timeout"           = 300
      "memory_size"       = 512
      "concurrency"       = -1
    }
    text_message_delivery = {
      "name"              = "scheduled-batch-text-message-delivery"
      "zip_name"          = "scheduled-batch-text-message-delivery"
      "description"       = "Delivery Lambda function for scheduled batch message delivery - text_message"
      "handler_file_name" = "index"
      "source_path_file"  = "index.js"
      "timeout"           = 300
      "memory_size"       = 512
      "concurrency"       = -1
    }
    webhook_delivery = {
      "name"              = "webhook-delivery"
      "zip_name"          = "webhook-delivery"
      "description"       = "Delivery Lambda function For Webhook Message"
      "handler_file_name" = "index"
      "source_path_file"  = "index.js"
      "timeout"           = 300
      "memory_size"       = 512
      "concurrency"       = -1
    }
    instant_scheduler = {
      "name"              = "instant-batch-scheduler"
      "zip_name"          = "instant-batch-scheduler"
      "description"       = "Instance Scheduler Lambda function for scheduled batch message delivery"
      "handler_file_name" = "instant_scheduler"
      "source_path_file"  = "instant_scheduler.js"
      "timeout"           = 300
      "memory_size"       = 512
      "concurrency"       = -1
    }
    email_delivery = {
      "name"              = "email-delivery"
      "zip_name"          = "email-delivery"
      "description"       = "Delivery Lambda function For Email Message"
      "handler_file_name" = "email_delivery"
      "source_path_file"  = "email_delivery.js"
      "timeout"           = 300
      "memory_size"       = 512
      "concurrency"       = -1
    }
    web_push_delivery = {
      "name"              = "web-push-delivery"
      "zip_name"          = "web-push-delivery"
      "description"       = "Delivery Lambda function For Web Push"
      "handler_file_name" = "web_push_delivery"
      "source_path_file"  = "web_push_delivery.js"
      "timeout"           = 300
      "memory_size"       = 512
      "concurrency"       = -1
    }
    cafe24_worker = {
      "name"              = "cafe24-worker"
      "zip_name"          = "cafe24-worker"
      "description"       = "Cafe24 Worker Lambda function"
      "handler_file_name" = "index"
      "source_path_file"  = "index.js"
      "timeout"           = 900
      "memory_size"       = 512
      "concurrency"       = -1
    }
    cafe24_app_push_notification_worker = {
      "name"              = "cafe24-app-push-notification-worker"
      "zip_name"          = "cafe24-app-push-notification-worker"
      "description"       = "Cafe24 App Push Notification Worker Lambda function"
      "handler_file_name" = "index"
      "source_path_file"  = "index.js"
      "timeout"           = 900
      "memory_size"       = 512
      "concurrency"       = -1
    }
    user_csv_mailer = {
      "name"              = "user-csv-mailer"
      "zip_name"          = "user-csv-mailer"
      "description"       = "User CSV Mailer Lambda function"
      "handler_file_name" = "index"
      "source_path_file"  = "index.js"
      "timeout"           = 600
      "memory_size"       = 512
      "concurrency"       = -1
    }
  }
}

variable "sqs" {
  description = "AWS sqs queues for scheduled batch message delivery."
  type        = map(any)
  default = {
    push = {
      "name"                       = "scheduled-batch-push-notification-queue"
      "description"                = "Push notification queue for scheduled batch message delivery"
      "visibility_timeout_seconds" = 600
      "max_receive_count"          = 1
    }
    scheduler_to_publisher = {
      "name"                       = "scheduled-batch-scheduler-to-publisher-queue"
      "description"                = "Queue for scheduler to publisher"
      "visibility_timeout_seconds" = 300
      "max_receive_count"          = 1
    }
    kakao_alimtalk = {
      "name"                       = "scheduled-batch-kakao-alimtalk-queue"
      "description"                = "Kakao alimtalk queue for scheduled batch message delivery"
      "visibility_timeout_seconds" = 600
      "max_receive_count"          = 1
    }
    kakao_friendtalk = {
      "name"                       = "scheduled-batch-kakao-friendtalk-queue"
      "description"                = "Kakao friendtalk queue for scheduled batch message delivery"
      "visibility_timeout_seconds" = 600
      "max_receive_count"          = 1
    }
    text_message = {
      "name"                       = "scheduled-batch-text-message-queue"
      "description"                = "Text message queue for scheduled batch message delivery"
      "visibility_timeout_seconds" = 600
      "max_receive_count"          = 1
    }
    email = {
      "name"                       = "email-delivery-queue"
      "description"                = "Delivery queue for email delivery"
      "visibility_timeout_seconds" = 600
      "max_receive_count"          = 1
    }
    webhook = {
      "name"                       = "webhook-delivery-queue"
      "description"                = "Delivery queue for webhook delivery"
      "visibility_timeout_seconds" = 600
      "max_receive_count"          = 1
    }
    campaign_instant = {
      "name"                       = "insatnt-batch-scheduler-queue"
      "description"                = "Campaign instant queue for scheduled batch message delivery"
      "visibility_timeout_seconds" = 300
      "max_receive_count"          = 1
    }
    web_push = {
      "name"                       = "web-push-delivery-queue"
      "description"                = "Delivery queue for web push delivery"
      "visibility_timeout_seconds" = 600
      "max_receive_count"          = 1
    }
    cafe24_worker = {
      "name"                       = "cafe24-worker-queue"
      "description"                = "Queue for dispatching jobs to Cafe24 worker"
      "visibility_timeout_seconds" = 600
      "max_receive_count"          = 1
    }
    user_csv_mailer = {
      "name"                       = "user-csv-mailer-queue"
      "description"                = "Queue for dispatching jobs to user csv mailer"
      "visibility_timeout_seconds" = 600
      "max_receive_count"          = 1
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
