
# Find the existing default VPC
data "aws_vpc" "default" {
  default = true
}

# Select the default subnet in the first Availability Zone (ap-south-1a)
data "aws_subnet" "selected" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "${var.aws_region}a"
  default_for_az    = true
}

# Find the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security group for EC2
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-monitoring-sg"
  description = "Security group for EC2 monitoring project"
  vpc_id      = data.aws_vpc.default.id

  # Allow outbound HTTPS for SSM communication
  egress {
    description = "Allow outbound HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instance
resource "aws_instance" "monitoring_ec2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  subnet_id                   = data.aws_subnet.selected.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_profile.name

  lifecycle {
    ignore_changes = [ami]
  }

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y httpd
    systemctl enable httpd
    systemctl start httpd
    echo "<h1>EC2 Monitoring Project</h1>" > /var/www/html/index.html
  EOF

  tags = {
    Name = "ec2-monitoring-instance"
  }
}
