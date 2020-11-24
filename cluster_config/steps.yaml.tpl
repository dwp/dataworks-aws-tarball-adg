---
BootstrapActions:
- Name: "start_ssm"
  ScriptBootstrapAction:
    Path: "s3://${s3_config_bucket}/component/tarball-adg/start_ssm.sh"
- Name: "metadata"
  ScriptBootstrapAction:
    Path: "s3://${s3_config_bucket}/component/tarball-adg/metadata.sh"
- Name: "get-dks-cert"
  ScriptBootstrapAction:
    Path: "s3://${s3_config_bucket}/component/tarball-adg/emr-setup.sh"
- Name: "installer"
  ScriptBootstrapAction:
    Path: "s3://${s3_config_bucket}/component/tarball-adg/installer.sh"
- Name: "metrics-setup"
  ScriptBootstrapAction:
    Path: "s3://${s3_config_bucket}/component/tarball-adg/metrics-setup.sh"
Steps:
- Name: "hive-setup"
  HadoopJarStep:
    Args:
    - "s3://${s3_config_bucket}/component/tarball-adg/hive-setup.sh"
    Jar: "s3://eu-west-2.elasticmapreduce/libs/script-runner/script-runner.jar"
  ActionOnFailure: "CONTINUE"
- Name: "submit-job"
  HadoopJarStep:
    Args:
    - "spark-submit"
    - "--master"
    - "yarn"
    - "--conf"
    - "spark.yarn.submit.waitAppCompletion=true"
    - "/opt/emr/generate_dataset_from_tarballs.py"
    Jar: "command-runner.jar"
  ActionOnFailure: "CANCEL_AND_WAIT"
- Name: "sns-notification"
  HadoopJarStep:
    Args:
    - "python3"
    - "/opt/emr/send_notification.py"
    Jar: "command-runner.jar"
  ActionOnFailure: "CONTINUE"
