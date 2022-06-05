data "aws_ec2_instance_type" "app_server" {
  instance_type = var.instance_type
}

data "aws_ami" "ubuntu_lts" {
  owners      = ["099720109477"] # Canonical
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = data.aws_ec2_instance_type.app_server.supported_architectures
  }
}

resource "aws_key_pair" "ssh_login" {
  key_name   = var.instance_name
  public_key = var.ssh_public_key
}

resource "aws_instance" "app_server" {
  ami                         = data.aws_ami.ubuntu_lts.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet_public.id
  vpc_security_group_ids      = [aws_security_group.security_group.id]
  associate_public_ip_address = true
  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  key_name = aws_key_pair.ssh_login.key_name

  tags = {
    Name = var.instance_name
  }
}
