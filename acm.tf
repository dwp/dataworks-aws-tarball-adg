resource "aws_acm_certificate" "tarball_adg" {
  certificate_authority_arn = data.terraform_remote_state.aws_certificate_authority.outputs.root_ca.arn
  domain_name               = "tarball-adg.${local.env_prefix[local.environment]}${local.dataworks_domain_name}"

  options {
    certificate_transparency_logging_preference = "DISABLED"
  }
}

data "aws_iam_policy_document" "tarball_adg_acm" {
  statement {
    effect = "Allow"

    actions = [
      "acm:ExportCertificate",
    ]

    resources = [
      aws_acm_certificate.tarball_adg.arn
    ]
  }
}

resource "aws_iam_policy" "tarball_adg_acm" {
  name        = "TarballADGACMExport"
  description = "Allow export of Dataset Generator certificate"
  policy      = data.aws_iam_policy_document.tarball_adg_acm.json
}
