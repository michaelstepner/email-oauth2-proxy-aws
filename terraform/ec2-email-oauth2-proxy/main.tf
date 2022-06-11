#-------------------------------------------------------------------------------
# Find AMI
#-------------------------------------------------------------------------------

data "aws_ec2_instance_type" "app_server" {
  instance_type = var.instance_type
}

data "aws_ami" "app_server" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["al2022-ami-minimal-*"]
  }

  filter {
    name   = "architecture"
    values = data.aws_ec2_instance_type.app_server.supported_architectures
  }
}

#-------------------------------------------------------------------------------
# Configure EC2 instance
#-------------------------------------------------------------------------------

resource "aws_key_pair" "ssh_login" {
  key_name   = var.instance_name
  public_key = var.ssh_public_key
}

resource "aws_instance" "app_server" {
  ami                         = data.aws_ami.app_server.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet_public.id
  vpc_security_group_ids      = [aws_security_group.security_group.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh_login.key_name
  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  user_data = templatefile(
    "scripts/configure-email-oauth2-proxy.yaml",
    {
      timezone                   = var.timezone
      email_oauth2_proxy_version = var.email_oauth2_proxy_version
      email_oauth2_proxy_config  = var.email_oauth2_proxy_config
    }
  )

  tags = {
    Name = var.instance_name
  }
}
