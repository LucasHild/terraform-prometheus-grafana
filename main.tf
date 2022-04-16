module "prometheus" {
  source              = "./modules/prometheus"
  hostname            = var.hostname_prometheus
  password            = var.password
  config_bucket_name  = var.config_bucket_name
  letsencrypt_email   = var.letsencrypt_email
  security_group_name = aws_security_group.security_group.name
  key_name            = var.key_name
  instance_ami        = data.aws_ami.ubuntu.id
  instance_profile    = aws_iam_instance_profile.ec2_profile.name
  instance_type       = var.instance_type_prometheus
}

module "alertmanager" {
  source              = "./modules/alertmanager"
  hostname            = var.hostname_alertmanager
  password            = var.password
  config_bucket_name  = var.config_bucket_name
  letsencrypt_email   = var.letsencrypt_email
  security_group_name = aws_security_group.security_group.name
  key_name            = var.key_name
  instance_ami        = data.aws_ami.ubuntu.id
  instance_profile    = aws_iam_instance_profile.ec2_profile.name
  instance_type       = var.instance_type_alertmanager
}

module "grafana" {
  source              = "./modules/grafana"
  hostname            = var.hostname_grafana
  password            = var.password
  config_bucket_name  = var.config_bucket_name
  letsencrypt_email   = var.letsencrypt_email
  security_group_name = aws_security_group.security_group.name
  key_name            = var.key_name
  instance_ami        = data.aws_ami.ubuntu.id
  instance_profile    = aws_iam_instance_profile.ec2_profile.name
  instance_type       = var.instance_type_grafana
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "security_group" {
  name        = "monitoring"
  description = "Security group for monitoring instances"

  # Either all rules should be defined inline or none should be defined inline.
  # Otherwise this can lead to mismatches and therefore attempts to overwrite configuration.
  # Since we need some non-inline rules, all rules are defined as non-inline rules.
  # Reference: https://github.com/hashicorp/terraform/issues/11011#issuecomment-283076580

  tags = {
    Name = "monitoring"
  }
}

resource "aws_security_group_rule" "security_group_ingress_http" {
  security_group_id = aws_security_group.security_group.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "security_group_ingress_https" {
  security_group_id = aws_security_group.security_group.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "security_group_egress" {
  security_group_id = aws_security_group.security_group.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "security_group_internal_self" {
  security_group_id = aws_security_group.security_group.id
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  type              = "ingress"
  self              = true
}

resource "aws_s3_bucket" "config_bucket" {
  bucket = var.config_bucket_name

  tags = {
    Name = "monitoring-config"
  }
}

resource "aws_iam_role" "ec2_role" {
  name        = "monitoring-ec2-role"
  description = "Allows EC2 instances to call AWS services on your behalf."
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "s3_access"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["s3:GetObject*", "s3:GetBucket*", "s3:List*"]
          Effect   = "Allow"
          Resource = ["arn:aws:s3:::${var.config_bucket_name}", "arn:aws:s3:::${var.config_bucket_name}/*"]
        },
      ]
    })
  }
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "monitoring-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_attach_ec2_access" {
  role       = aws_iam_role.ec2_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ec2_attach_cloudwatch_access" {
  role       = aws_iam_role.ec2_role.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ec2_attach_ssm_access" {
  count      = var.allow_session_manager ? 1 : 0
  role       = aws_iam_role.ec2_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
