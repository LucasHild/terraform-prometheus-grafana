variable "hostname_prometheus" {
  description = "Hostname for Prometheus"
  type        = string
}

variable "hostname_alertmanager" {
  description = "Hostname for Alertmanager"
  type        = string
}

variable "hostname_grafana" {
  description = "Hostname for Grafana"
  type        = string
}

variable "instance_type" {
  description = "Instance type for EC2 instance"
  type        = string
  default     = "t2.nano"
}

variable "config_bucket_name" {
  description = "Name of S3 bucket that stores config files"
  type        = string
}

variable "password" {
  description = "Password for web frontend"
  type        = string
}

variable "letsencrypt_email" {
  description = "Email for Let's Encrypt"
  type        = string
}

variable "key_name" {
  description = "Key name for EC2 instances"
  type        = string
  default     = ""
}
