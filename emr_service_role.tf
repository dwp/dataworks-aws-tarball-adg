data "aws_iam_policy_document" "emr_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["elasticmapreduce.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "tarball_adg_emr_service" {
  name               = "tarball_adg_emr_service"
  assume_role_policy = data.aws_iam_policy_document.emr_assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "emr_attachment" {
  role       = aws_iam_role.tarball_adg_emr_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
}

resource "aws_iam_role_policy_attachment" "tarball_adg_emr_service_ebs_cmk" {
  role       = aws_iam_role.tarball_adg_emr_service.name
  policy_arn = aws_iam_policy.tarball_adg_ebs_cmk_encrypt.arn
}
