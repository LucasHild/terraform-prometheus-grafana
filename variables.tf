variable "prometheus_hostname" {
  description = "Hostname for Prometheus"
  type        = string
}

variable "alertmanager_hostname" {
  description = "Hostname for Alertmanager"
  type        = string
}

variable "grafana_hostname" {
  description = "Hostname for Grafana"
  type        = string
}

variable "config_bucket_name" {
  description = "Name of S3 bucket that stores config files"
  type        = string
}

variable "password" {
  description = "Password for web frontend"
  type        = string
}
