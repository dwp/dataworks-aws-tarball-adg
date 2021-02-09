resource "aws_s3_bucket_object" "generate_dataset_from_tarballs_script" {
  bucket = data.terraform_remote_state.common.outputs.config_bucket.id
  key    = "component/tarball-adg/generate_dataset_from_tarballs.py"
  content = templatefile("${path.module}/steps/generate_dataset_from_tarballs.py",
    {
      secret_name            = local.secret_name
      published_db           = local.published_db
      hive_metastore_backend = local.hive_metastore_backend[local.environment]
      data_pipeline_metadata = local.data_pipeline_metadata
      file_location          = "analytical-dataset"
      url                    = format("%s/datakey/actions/decrypt", data.terraform_remote_state.crypto.outputs.dks_endpoint[local.environment])
      aws_default_region     = data.aws_region.current.name
      log_path               = "/var/log/tarball-adg/generate-analytical-dataset.log"
      s3_prefix              = var.htme_data_location[local.environment]
    }
  )
}

resource "aws_s3_bucket_object" "hive_setup_sh" {
  bucket = data.terraform_remote_state.common.outputs.config_bucket.id
  key    = "component/tarball-adg/hive-setup.sh"
  content = templatefile("${path.module}/steps/hive-setup.sh",
    {
      python_logger               = format("s3://%s/%s", data.terraform_remote_state.common.outputs.config_bucket.id, aws_s3_bucket_object.logger.key)
      generate_analytical_dataset = format("s3://%s/%s", data.terraform_remote_state.common.outputs.config_bucket.id, aws_s3_bucket_object.generate_dataset_from_tarballs_script.key)
      published_db                = local.published_db
    }
  )
}

resource "aws_s3_bucket_object" "logger" {
  bucket  = data.terraform_remote_state.common.outputs.config_bucket.id
  key     = "component/tarball-adg/logger.py"
  content = file("${path.module}/steps/logger.py")
}

resource "aws_s3_bucket_object" "metrics_setup_sh" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  key        = "component/tarball-adg/metrics-setup.sh"
  content = templatefile("${path.module}/steps/metrics-setup.sh",
    {
      proxy_url          = data.terraform_remote_state.internal_compute.outputs.internet_proxy.url
      metrics_properties = format("s3://%s/%s", data.terraform_remote_state.common.outputs.config_bucket.id, aws_s3_bucket_object.metrics_properties.key)
      metrics_pom        = format("s3://%s/%s", data.terraform_remote_state.common.outputs.config_bucket.id, aws_s3_bucket_object.metrics_pom.key)
      metrics_jar        = format("s3://%s/%s", data.terraform_remote_state.common.outputs.config_bucket.id, aws_s3_bucket_object.metrics_jar.key)
    }
  )
}

resource "aws_s3_bucket_object" "metrics_properties" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  key        = "component/tarball-adg/metrics/metrics.properties"
  content = templatefile("${path.module}/steps/metrics_config/metrics.properties",
    {
      adg_pushgateway_hostname = data.terraform_remote_state.metrics_infrastructure.outputs.adg_pushgateway_hostname
    }
  )
}

resource "aws_s3_bucket_object" "metrics_pom" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  key        = "component/tarball-adg/metrics/pom.xml"
  content    = file("${path.module}/steps/metrics_config/pom.xml")
}

resource "aws_s3_bucket_object" "metrics_jar" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  key        = "component/tarball-adg/metrics/adg-exporter.jar"
  content    = filebase64("${var.analytical_dataset_generation_exporter_jar.base_path}/exporter-${var.analytical_dataset_generation_exporter_jar.version}.jar")
}

resource "aws_s3_bucket_object" "send_notification_script" {
  bucket = data.terraform_remote_state.common.outputs.config_bucket.id
  key    = "component/tarball-adg/send_notification.py"
  content = templatefile("${path.module}/steps/send_notification.py",
    {
      publish_bucket   = data.terraform_remote_state.common.outputs.published_bucket.id
      status_topic_arn = aws_sns_topic.tarball_adg_completion_status_sns.arn
      log_path         = "/var/log/tarball-adg/adg_params.log"
    }
  )
}
