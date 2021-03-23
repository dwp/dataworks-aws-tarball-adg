variable "emr_launcher_zip" {
  type = map(string)

  default = {
    base_path = ""
    version   = ""
  }
}

resource "aws_lambda_function" "tarball_adg_emr_launcher" {
  filename      = "${var.emr_launcher_zip["base_path"]}/emr-launcher-${var.emr_launcher_zip["version"]}.zip"
  function_name = "tarball_adg_emr_launcher"
  role          = aws_iam_role.tarball_adg_emr_launcher_lambda_role.arn
  handler       = "emr_launcher.handler"
  runtime       = "python3.7"
  source_code_hash = filebase64sha256(
    format(
      "%s/emr-launcher-%s.zip",
      var.emr_launcher_zip["base_path"],
      var.emr_launcher_zip["version"]
    )
  )
  publish = false
  timeout = 60

  environment {
    variables = {
      EMR_LAUNCHER_CONFIG_S3_BUCKET = data.terraform_remote_state.common.outputs.config_bucket.id
      EMR_LAUNCHER_CONFIG_S3_FOLDER = "emr/tarball-adg"
      EMR_LAUNCHER_LOG_LEVEL        = "debug"
    }
  }
}

resource "aws_iam_role" "tarball_adg_emr_launcher_lambda_role" {
  name               = "tarball_adg_emr_launcher_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.tarball_adg_emr_launcher_assume_policy.json
}

data "aws_iam_policy_document" "tarball_adg_emr_launcher_assume_policy" {
  statement {
    sid     = "TarballADGEMRLauncherLambdaAssumeRolePolicy"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "tarball_adg_emr_launcher_read_s3_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      format("arn:aws:s3:::%s/emr/tarball-adg/*", data.terraform_remote_state.common.outputs.config_bucket.id)
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]
    resources = [
      data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
    ]
  }
}

data "aws_iam_policy_document" "tarball_adg_emr_launcher_runjobflow_policy" {
  statement {
    effect = "Allow"
    actions = [
      "elasticmapreduce:RunJobFlow",
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "tarball_adg_emr_launcher_pass_role_document" {
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      "arn:aws:iam::*:role/*"
    ]
  }
}

resource "aws_iam_policy" "tarball_adg_emr_launcher_read_s3_policy" {
  name        = "TarballADGReadS3"
  description = "Allow Tarball ADG to read from S3 bucket"
  policy      = data.aws_iam_policy_document.tarball_adg_emr_launcher_read_s3_policy.json
}

resource "aws_iam_policy" "tarball_adg_emr_launcher_runjobflow_policy" {
  name        = "TarballADGRunJobFlow"
  description = "Allow Tarball ADG to run job flow"
  policy      = data.aws_iam_policy_document.tarball_adg_emr_launcher_runjobflow_policy.json
}

resource "aws_iam_policy" "tarball_adg_emr_launcher_pass_role_policy" {
  name        = "TarballADGPassRole"
  description = "Allow TarballADG to pass role"
  policy      = data.aws_iam_policy_document.tarball_adg_emr_launcher_pass_role_document.json
}

resource "aws_iam_role_policy_attachment" "tarball_adg_emr_launcher_read_s3_attachment" {
  role       = aws_iam_role.tarball_adg_emr_launcher_lambda_role.name
  policy_arn = aws_iam_policy.tarball_adg_emr_launcher_read_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "tarball_adg_emr_launcher_runjobflow_attachment" {
  role       = aws_iam_role.tarball_adg_emr_launcher_lambda_role.name
  policy_arn = aws_iam_policy.tarball_adg_emr_launcher_runjobflow_policy.arn
}

resource "aws_iam_role_policy_attachment" "tarball_adg_emr_launcher_pass_role_attachment" {
  role       = aws_iam_role.tarball_adg_emr_launcher_lambda_role.name
  policy_arn = aws_iam_policy.tarball_adg_emr_launcher_pass_role_policy.arn
}

resource "aws_iam_role_policy_attachment" "tarball_adg_emr_launcher_policy_execution" {
  role       = aws_iam_role.tarball_adg_emr_launcher_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# For now, we do not want this to trigger, but we may if we use this solution again in the future, hence commented out

# resource "aws_sns_topic_subscription" "uc_export_to_crown_completion_status_subscription" {
#   topic_arn = data.terraform_remote_state.internal_compute.outputs.export_status_sns_fulls.arn
#   protocol  = "lambda"
#   endpoint  = aws_lambda_function.tarball_adg_emr_launcher.arn
# }

# resource "aws_lambda_permission" "tarball_adg_emr_launcher_subscription_eccs" {
#   statement_id  = "ExportFullsStatusFromSNS"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.tarball_adg_emr_launcher.function_name
#   principal     = "sns.amazonaws.com"
#   source_arn    = data.terraform_remote_state.internal_compute.outputs.export_status_sns_fulls.arn
# }

resource "aws_iam_role_policy_attachment" "tarball_adg_emr_launcher_getsecrets" {
  role       = aws_iam_role.tarball_adg_emr_launcher_lambda_role.name
  policy_arn = "arn:aws:iam::${local.account[local.environment]}:policy/ADGGetSecrets"
}
