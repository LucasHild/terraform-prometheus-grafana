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
  instance_type       = "t2.micro"
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

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Monitoring Security Group"
  }
}

# Allow Prometheus to access other instances (i.e. Alertmanager) in security on port 3000
# This rule depends on both security group and instance so separating it allows it to be created after both
resource "aws_security_group_rule" "security_group_internal_prometheus" {
  security_group_id = aws_security_group.security_group.id
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  type              = "ingress"
  cidr_blocks       = ["${module.prometheus.public_ip}/32"]
}

# Allow Grafana to access other instances (i.e. Promehteus) in security on port 3000
# This rule depends on both security group and instance so separating it allows it to be created after both
resource "aws_security_group_rule" "security_group_internal_grafana" {
  security_group_id = aws_security_group.security_group.id
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  type              = "ingress"
  cidr_blocks       = ["${module.grafana.public_ip}/32"]
}

resource "aws_s3_bucket" "config_bucket" {
  bucket = var.config_bucket_name

  tags = {
    Name = "Monitoring Config"
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "MonitoringEC2Instance"
  description        = "Allows EC2 instances to call AWS services on your behalf."
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_attach_s3_access" {
  role       = aws_iam_role.ec2_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "ec2_attach_ec2_access" {
  role       = aws_iam_role.ec2_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ec2_attach_cloudwatch_access" {
  role       = aws_iam_role.ec2_role.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}
