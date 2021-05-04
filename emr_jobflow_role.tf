data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "tarball_adg" {
  name               = "tarball_adg"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = local.tags
}

resource "aws_iam_instance_profile" "tarball_adg" {
  name = "tarball_adg"
  role = aws_iam_role.tarball_adg.id
}

resource "aws_iam_role_policy_attachment" "ec2_for_ssm_attachment" {
  role       = aws_iam_role.tarball_adg.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "amazon_ssm_managed_instance_core" {
  role       = aws_iam_role.tarball_adg.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "tarball_adg_ebs_cmk" {
  role       = aws_iam_role.tarball_adg.name
  policy_arn = aws_iam_policy.tarball_adg_ebs_cmk_encrypt.arn
}

data "aws_iam_policy_document" "tarball_adg_write_parquet" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    resources = [
      data.terraform_remote_state.common.outputs.published_bucket.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject*",
      "s3:DeleteObject*",
      "s3:PutObject*",
    ]

    resources = [
      "${data.terraform_remote_state.common.outputs.published_bucket.arn}/tarball-analytical-dataset/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    resources = [
      data.terraform_remote_state.common.outputs.published_bucket_cmk.arn,
    ]
  }
}

resource "aws_iam_policy" "tarball_adg_write_parquet" {
  name        = "TarballADGWriteParquet"
  description = "Allow writing of Tarball ADG parquet files"
  policy      = data.aws_iam_policy_document.tarball_adg_write_parquet.json
}

resource "aws_iam_role_policy_attachment" "tarball_adg_write_parquet" {
  role       = aws_iam_role.tarball_adg.name
  policy_arn = aws_iam_policy.tarball_adg_write_parquet.arn
}

resource "aws_iam_role_policy_attachment" "tarball_adg_gluetables" {
  role       = aws_iam_role.tarball_adg.name
  policy_arn = aws_iam_policy.tarball_adg_gluetables_write.arn
}

resource "aws_iam_role_policy_attachment" "tarball_adg_acm" {
  role       = aws_iam_role.tarball_adg.name
  policy_arn = aws_iam_policy.tarball_adg_acm.arn
}

resource "aws_iam_role_policy_attachment" "emr_tarball_adg_secretsmanager" {
  role       = aws_iam_role.tarball_adg.name
  policy_arn = aws_iam_policy.tarball_adg_secretsmanager.arn
}

data "aws_iam_policy_document" "tarball_adg_write_logs" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    resources = [
      data.terraform_remote_state.security-tools.outputs.logstore_bucket.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject*",
      "s3:PutObject*",

    ]

    resources = [
      "${data.terraform_remote_state.security-tools.outputs.logstore_bucket.arn}/${local.s3_log_prefix}",
    ]
  }
}

resource "aws_iam_policy" "tarball_adg_write_logs" {
  name        = "TarballADGWriteLogs"
  description = "Allow writing of Tarball ADG logs"
  policy      = data.aws_iam_policy_document.tarball_adg_write_logs.json
}

resource "aws_iam_role_policy_attachment" "tarball_adg_write_logs" {
  role       = aws_iam_role.tarball_adg.name
  policy_arn = aws_iam_policy.tarball_adg_write_logs.arn
}

data "aws_iam_policy_document" "tarball_adg_read_config" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    resources = [
      data.terraform_remote_state.common.outputs.config_bucket.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject*",
    ]

    resources = [
      "${data.terraform_remote_state.common.outputs.config_bucket.arn}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
    ]

    resources = [
      "${data.terraform_remote_state.common.outputs.config_bucket_cmk.arn}",
    ]
  }
}

resource "aws_iam_policy" "tarball_adg_read_config" {
  name        = "TarballADGReadConfig"
  description = "Allow reading of Tarball ADG config files"
  policy      = data.aws_iam_policy_document.tarball_adg_read_config.json
}

resource "aws_iam_role_policy_attachment" "tarball_adg_read_config" {
  role       = aws_iam_role.tarball_adg.name
  policy_arn = aws_iam_policy.tarball_adg_read_config.arn
}

data "aws_iam_policy_document" "tarball_adg_read_artefacts" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    resources = [
      data.terraform_remote_state.management_artefact.outputs.artefact_bucket.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject*",
    ]

    resources = [
      "${data.terraform_remote_state.management_artefact.outputs.artefact_bucket.arn}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
    ]

    resources = [
      data.terraform_remote_state.management_artefact.outputs.artefact_bucket.cmk_arn,
    ]
  }
}

resource "aws_iam_policy" "tarball_adg_read_artefacts" {
  name        = "TarballADGReadArtefacts"
  description = "Allow reading of Tarball ADG software artefacts"
  policy      = data.aws_iam_policy_document.tarball_adg_read_artefacts.json
}

resource "aws_iam_role_policy_attachment" "tarball_adg_read_artefacts" {
  role       = aws_iam_role.tarball_adg.name
  policy_arn = aws_iam_policy.tarball_adg_read_artefacts.arn
}

data "aws_iam_policy_document" "tarball_adg_write_dynamodb" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:*",
    ]

    resources = [
      "arn:aws:dynamodb:${var.region}:${local.account[local.environment]}:table/${local.emrfs_metadata_tablename}",
      "arn:aws:dynamodb:${var.region}:${local.account[local.environment]}:table/${local.data_pipeline_metadata}"
    ]
  }
}

resource "aws_iam_policy" "tarball_adg_write_dynamodb" {
  name        = "TarballADGDynamoDB"
  description = "Allows read and write access to Tarball ADG's EMRFS DynamoDB table"
  policy      = data.aws_iam_policy_document.tarball_adg_write_dynamodb.json
}

resource "aws_iam_role_policy_attachment" "tarball_adg_dynamodb" {
  role       = aws_iam_role.tarball_adg.name
  policy_arn = aws_iam_policy.tarball_adg_write_dynamodb.arn
}

data "aws_iam_policy_document" "tarball_adg_metadata_change" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:ModifyInstanceMetadataOptions",
    ]

    resources = [
      "arn:aws:ec2:${var.region}:${local.account[local.environment]}:instance/*",
    ]
  }
}

resource "aws_iam_policy" "tarball_adg_metadata_change" {
  name        = "TarballADGMetadataOptions"
  description = "Allow editing of Metadata Options"
  policy      = data.aws_iam_policy_document.tarball_adg_metadata_change.json
}

resource "aws_iam_role_policy_attachment" "tarball_adg_metadata_change" {
  role       = aws_iam_role.tarball_adg.name
  policy_arn = aws_iam_policy.tarball_adg_metadata_change.arn
}

data "aws_iam_policy_document" "tarball_adg_read_tarballs" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    resources = [
      format("arn:aws:s3:::%s", data.terraform_remote_state.ingest.outputs.s3_buckets.htme_bucket),
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject*",
    ]

    resources = [
      format("arn:aws:s3:::%s/%s/*", data.terraform_remote_state.ingest.outputs.s3_buckets.htme_bucket, "business-data/tarball-mongo/ucdata/*")
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
    ]

    resources = [
      "${data.terraform_remote_state.internal_compute.outputs.compaction_bucket_cmk.arn}",
    ]
  }
}

resource "aws_iam_policy" "tarball_adg_read_tarballs" {
  name        = "TarballADGReadTarballs"
  description = "Allow reading of Tarball Ingestion output files"
  policy      = data.aws_iam_policy_document.tarball_adg_read_tarballs.json
}

resource "aws_iam_role_policy_attachment" "tarball_adg_read_tarballs" {
  role       = aws_iam_role.tarball_adg.name
  policy_arn = aws_iam_policy.tarball_adg_read_tarballs.arn
}


resource "aws_iam_policy" "tarball_adg_publish_sns" {
  name        = "TarballADGPublishSNS"
  description = "Allow Tarball ADG to publish SNS messages"
  policy      = data.aws_iam_policy_document.tarball_adg_sns_topic_policy_for_completion_status.json
}

resource "aws_iam_role_policy_attachment" "tarball_adg_publish_sns" {
  role       = aws_iam_role.tarball_adg.name
  policy_arn = aws_iam_policy.tarball_adg_publish_sns.arn
}

data "aws_iam_policy_document" "tarball_adg_sns_topic_policy_for_completion_status" {
  statement {
    sid = "TarballADGCompletionStatusSNS"

    actions = [
      "SNS:Publish",
    ]

    effect = "Allow"

    resources = [
      aws_sns_topic.tarball_adg_completion_status_sns.arn,
    ]
  }
}
