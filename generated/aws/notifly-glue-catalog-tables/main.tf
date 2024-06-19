data "aws_s3_bucket" "notifly_event_logs_bucket" {
  bucket = "notifly-event-logs"
}

data "aws_s3_bucket" "notifly_message_events_bucket" {
  bucket = "notifly-message-events"
}

data "aws_s3_bucket" "triggering_events_bucket" {
  bucket = "notifly-triggering-events"
}

data "aws_s3_bucket" "notifly_experiment_intermediate_results_bucket" {
  bucket = "notifly-experiment-intermediate-results"
}

resource "aws_glue_catalog_database" "notifly_analytics_database" {
  name = "notifly_analytics"
}

resource "aws_glue_catalog_table" "event_logs_catalog_table" {
  database_name = aws_glue_catalog_database.notifly_analytics_database.name
  name          = "notifly_event_logs"
  description   = "Glue table for our new data pipeline"
  table_type    = "EXTERNAL_TABLE"
  parameters = {
    classification                = "parquet"
    "partition_filtering.enabled" = "true"
  }

  partition_keys {
    name = "project_id"
    type = "string"
  }
  partition_keys {
    name = "dt"
    type = "string"
  }
  partition_keys {
    name = "h"
    type = "string"
  }
  partition_keys {
    name = "pre_conversion"
    type = "string"
  }

  partition_index {
    keys       = ["project_id"]
    index_name = "project_id_index"
  }

  partition_index {
    keys       = ["dt", "h"]
    index_name = "dt_h_index"
  }

  partition_index {
    keys       = ["pre_conversion"]
    index_name = "pre_conversion_index"
  }

  storage_descriptor {
    bucket_columns            = []
    compressed                = false
    input_format              = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    location                  = "s3://${data.aws_s3_bucket.notifly_event_logs_bucket.bucket}/data/"
    output_format             = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    stored_as_sub_directories = false

    columns {
      name       = "time"
      type       = "bigint"
      parameters = {}
    }
    columns {
      name       = "notifly_user_id"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "name"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "external_user_id"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "id"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "is_internal_event"
      type       = "boolean"
      parameters = {}
    }
    columns {
      name       = "segmentation_event_param_keys"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "platform"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "os_version"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "app_version"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "is_global_event"
      type       = "boolean"
      parameters = {}
    }
    columns {
      name       = "is_server_side_event"
      type       = "boolean"
      parameters = {}
    }
    columns {
      name       = "notifly_device_id"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "event_params"
      type       = "map<string,string>"
      parameters = {}
    }
    columns {
      name       = "external_device_id"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "device_token"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "amplitude_id"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "sdk_version"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "sdk_type"
      type       = "string"
      parameters = {}
    }
    ser_de_info {
      parameters = {
        "serialization.format" = "1"
      }
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }
  }
}

resource "aws_glue_catalog_table" "message_events_catalog_table" {
  database_name = aws_glue_catalog_database.notifly_analytics_database.name
  name          = "notifly_message_events"
  description   = "Glue table for message events in our new data pipeline"
  table_type    = "EXTERNAL_TABLE"
  parameters = {
    classification                = "parquet"
    "partition_filtering.enabled" = "true"
  }

  partition_keys {
    name = "project_id"
    type = "string"
  }
  partition_keys {
    name = "campaign_id"
    type = "string"
  }
  partition_keys {
    name = "dt"
    type = "string"
  }
  partition_keys {
    name = "h"
    type = "string"
  }
  partition_keys {
    name = "pre_conversion"
    type = "string"
  }

  partition_index {
    keys       = ["project_id"]
    index_name = "project_id_index"
  }
  partition_index {
    keys       = ["campaign_id", "pre_conversion"]
    index_name = "campaign_id_pre_conversion_index"
  }
  partition_index {
    keys       = ["dt", "h"]
    index_name = "dt_h_index"
  }

  storage_descriptor {
    bucket_columns            = []
    compressed                = false
    input_format              = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    location                  = "s3://${data.aws_s3_bucket.notifly_message_events_bucket.bucket}/data/"
    output_format             = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    stored_as_sub_directories = false

    columns {
      name       = "id"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "type"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "name"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "time"
      type       = "bigint"
      parameters = {}
    }
    columns {
      name       = "variant_id"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "notifly_user_id"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "notifly_device_id"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "event_params"
      type       = "map<string,string>"
      parameters = {}
    }
    columns {
      name       = "external_source"
      type       = "string"
      parameters = {}
    }

    ser_de_info {
      parameters = {
        "serialization.format" = "1"
      }
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }
  }
}

resource "aws_glue_catalog_table" "triggering_events_catalog_table" {
  database_name = aws_glue_catalog_database.notifly_analytics_database.name
  name          = "notifly_triggering_events"
  description   = "Glue table for triggering events in our new data pipeline"
  table_type    = "EXTERNAL_TABLE"
  parameters = {
    classification                = "parquet"
    "partition_filtering.enabled" = "true"
  }

  partition_keys {
    name = "project_id"
    type = "string"
  }
  partition_keys {
    name = "campaign_id"
    type = "string"
  }
  partition_keys {
    name = "experiment_id"
    type = "string"
  }
  partition_keys {
    name = "dt"
    type = "string"
  }
  partition_keys {
    name = "h"
    type = "string"
  }

  partition_index {
    keys       = ["project_id"]
    index_name = "project_id_index"
  }
  partition_index {
    keys       = ["campaign_id", "experiment_id"]
    index_name = "campaign_id_experiment_id_index"
  }
  partition_index {
    keys       = ["dt", "h"]
    index_name = "dt_h_index"
  }

  storage_descriptor {
    bucket_columns            = []
    compressed                = false
    input_format              = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    location                  = "s3://${data.aws_s3_bucket.triggering_events_bucket.bucket}/data/"
    output_format             = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    stored_as_sub_directories = false

    columns {
      name       = "triggering_event_id"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "variant_id"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "notifly_user_id"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "external_user_id"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "platform"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "time"
      type       = "bigint"
      parameters = {}
    }
    columns {
      name       = "triggering_event_version"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "triggering_source"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "event_params"
      type       = "map<string,string>"
      parameters = {}
    }

    ser_de_info {
      parameters = {
        "serialization.format" = "1"
      }
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }
  }
}

resource "aws_glue_catalog_table" "notifly_experiment_intermediate_results_table" {
  database_name = aws_glue_catalog_database.notifly_analytics_database.name
  name          = "notifly_experiment_intermediate_results"
  description   = "Glue table for experiment intermediate results in our new data pipeline"
  table_type    = "EXTERNAL_TABLE"
  parameters = {
    classification                = "parquet"
    "partition_filtering.enabled" = "true"
  }


  partition_keys {
    name = "scorecard_date"
    type = "string"
  }
  partition_keys {
    name = "project_id"
    type = "string"
  }
  partition_keys {
    name = "campaign_id"
    type = "string"
  }
  partition_keys {
    name = "experiment_id"
    type = "string"
  }

  partition_index {
    keys       = ["scorecard_date"]
    index_name = "scorecard_date_index"
  }

  partition_index {
    keys       = ["project_id"]
    index_name = "project_id_index"
  }

  partition_index {
    keys       = ["campaign_id", "experiment_id"]
    index_name = "campaign_id_experiment_id_index"
  }

  storage_descriptor {
    bucket_columns            = []
    compressed                = false
    input_format              = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    location                  = "s3://${data.aws_s3_bucket.notifly_experiment_intermediate_results_bucket.bucket}/data/"
    output_format             = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    stored_as_sub_directories = false

    columns {
      name       = "variant_id"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "subject_key"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "subject_value"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "metric_name"
      type       = "string"
      parameters = {}
    }
    columns {
      name       = "value"
      type       = "bigint"
      parameters = {}
    }

    ser_de_info {
      parameters = {
        "serialization.format" = "1"
      }
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }
  }
}
