data "aws_secretsmanager_secret" "tarball_adg_secret" {
  name = local.secret_name
}

data "aws_iam_policy_document" "tarball_adg_secretsmanager" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      data.aws_secretsmanager_secret.tarball_adg_secret.arn
    ]
  }
}

resource "aws_iam_policy" "tarball_adg_secretsmanager" {
  name        = "TarballADGSecretsManagerRead"
  description = "Allow reading of Tarball ADG config values"
  policy      = data.aws_iam_policy_document.tarball_adg_secretsmanager.json
}
