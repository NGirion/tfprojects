output "web_server_public_ip" {
  description = "Public IP of the Web Server"
  value       = aws_instance.web.public_ip
}

