output "public_ip_prometheus" {
  value       = module.prometheus.public_ip
  description = "Public IPv4 address of Prometheus instance"
}

output "public_ip_alertmanager" {
  value       = module.alertmanager.public_ip
  description = "Public IPv4 address of Alertmanager instance"
}

output "public_ip_grafana" {
  value       = module.grafana.public_ip
  description = "Public IPv4 address of Grafana instance"
}
