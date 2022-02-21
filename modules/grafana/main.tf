resource "aws_instance" "instance" {
  ami                  = var.instance_ami
  instance_type        = var.instance_type
  availability_zone    = "eu-central-1c"
  user_data            = data.template_file.cloud_config_script.rendered
  security_groups      = [var.security_group_name]
  iam_instance_profile = var.instance_profile
  key_name             = var.key_name

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name = "monitoring-grafana"
  }
}

data "template_file" "cloud_config_script" {
  template = file("${path.module}/cloud.conf")

  vars = {
    hostname           = var.hostname
    config_bucket_name = var.config_bucket_name
    password           = var.password
    letsencrypt_email  = var.letsencrypt_email
  }
}
