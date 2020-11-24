resource "aws_glue_catalog_database" "tarball_adg" {
  name        = "tarball_adg"
  description = "Database for the Tarball ADG"
}

output "tarball_adg" {
  value = {
    job_name = aws_glue_catalog_database.tarball_adg.name
  }
}

resource "aws_glue_catalog_database" "tarball_adg_staging" {
  name        = "tarball_adg_staging"
  description = "Staging Database for Tarball ADG"
}

output "tarball_adg_staging" {
  value = {
    job_name = aws_glue_catalog_database.tarball_adg_staging.name
  }
}

data "aws_iam_policy_document" "tarball_adg_gluetables_write" {
  statement {
    effect = "Allow"

    actions = [
      "glue:GetTable*",
      "glue:GetDatabase*",
      "glue:DeleteTable",
      "glue:CreateTable",
      "glue:GetPartitions",
      "glue:GetUserDefinedFunctions"
    ]

    resources = [
      "arn:aws:glue:${var.region}:${local.account[local.environment]}:table/tarball_adg_staging/*",
      "arn:aws:glue:${var.region}:${local.account[local.environment]}:table/tarball_adg/*",
      "arn:aws:glue:${var.region}:${local.account[local.environment]}:database/default",
      "arn:aws:glue:${var.region}:${local.account[local.environment]}:table/default/*",
      "arn:aws:glue:${var.region}:${local.account[local.environment]}:database/tarball_adg_staging",
      "arn:aws:glue:${var.region}:${local.account[local.environment]}:database/tarball_adg",
      "arn:aws:glue:${var.region}:${local.account[local.environment]}:database/global_temp",
      "arn:aws:glue:${var.region}:${local.account[local.environment]}:catalog",
      "arn:aws:glue:${var.region}:${local.account[local.environment]}:userDefinedFunction/tarball_adg_staging/*",
      "arn:aws:glue:${var.region}:${local.account[local.environment]}:userDefinedFunction/tarball_adg/*",
      "arn:aws:glue:${var.region}:${local.account[local.environment]}:userDefinedFunction/default/*"
    ]
  }
}

resource "aws_iam_policy" "tarball_adg_gluetables_write" {
  name        = "TarballADGGlueTablesWrite"
  description = "Allow creation and deletion of Tarball ADG Glue tables"
  policy      = data.aws_iam_policy_document.tarball_adg_gluetables_write.json
}
