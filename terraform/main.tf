# Cấu hình Provider
provider "aws" {
  region = "ap-southeast-1" # Đổi lại theo region của bạn, ví dụ: us-east-1
}

# Variable cho public key
variable "public_key" {
  description = "SSH public key for EC2 access"
  type        = string
}

# Tạo Security Group mở các port cần thiết cho dự án
resource "aws_security_group" "devops_sg" {
  name        = "devops_final_sg"
  description = "Security group for DevOps Final Project"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Prometheus
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Grafana
  ingress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound traffic (Allow all)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Tạo AWS Key Pair từ public key
resource "aws_key_pair" "devops_key" {
  key_name   = "devops-final-key"
  public_key = var.public_key
}

# Tạo máy chủ EC2 Ubuntu
resource "aws_instance" "devops_server" {
  ami           = "ami-0fa377108253bf620" # Ubuntu 22.04 LTS ở ap-southeast-1 (Singapore)
  instance_type = "t2.micro"              # Free tier
  key_name      = aws_key_pair.devops_key.key_name
  security_groups = [aws_security_group.devops_sg.name]

  # User Data script cài đặt tự động Docker & Docker Compose
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y ca-certificates curl gnupg
              sudo install -m 0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              sudo chmod a+r /etc/apt/keyrings/docker.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
              sudo apt-get update
              sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
              sudo systemctl enable docker
              sudo systemctl start docker
              sudo usermod -aG docker ubuntu
              EOF

  tags = {
    Name = "DevOps-Final-Project"
  }
}
