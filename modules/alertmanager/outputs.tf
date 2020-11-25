output "public_ip" {
  value       = aws_instance.instance.public_ip
  description = "Public IPv4 address of instance"
}
