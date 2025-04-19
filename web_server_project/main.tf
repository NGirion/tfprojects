provider "aws" {
  region = "eu-north-1"
}

# Generate SSH key pair
resource "tls_private_key" "web_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create EC2 key pair in AWS using generated public key
resource "aws_key_pair" "web_key" {
  key_name   = "myterraform"
  public_key = tls_private_key.web_key.public_key_openssh
}

# Save the private key locally to use for SSH access
resource "local_file" "private_key" {
  content  = tls_private_key.web_key.private_key_pem
  filename = "${path.module}/myterraform.pem"
  file_permission = "0400"
}

# Get default VPC and Subnet
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Create Security Group for HTTP & SSH
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow SSH and HTTP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch EC2 instance with Apache web server
resource "aws_instance" "web" {
  ami                    = "ami-00dac429de3db4247" # Ubuntu 22.04 in eu-north-1
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.web_key.key_name
  subnet_id              = data.aws_subnet.default.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y apache2
              echo "<h1>Hello from Terraform Web Server 🚀</h1>" > /var/www/html/index.html
              systemctl start apache2
              systemctl enable apache2
              EOF

  tags = {
    Name = "TerraformWebServer"
  }
}

# Output the public IP
output "web_instance_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.web.public_ip
}

