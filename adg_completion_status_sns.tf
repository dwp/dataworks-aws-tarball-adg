resource "aws_sns_topic" "tarball_adg_completion_status_sns" {
  name = "tarball_adg_completion_status_sns"

  tags = merge(
    local.common_tags,
    {
      "Name" = "tarball_adg_completion_status_sns"
    },
  )
}

output "tarball_adg_completion_status_sns_topic" {
  value = aws_sns_topic.tarball_adg_completion_status_sns
}
