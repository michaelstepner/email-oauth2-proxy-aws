#-------------------------------------------------------------------------------
# Domain (must be already registered in AWS Route 53)
#-------------------------------------------------------------------------------

resource "aws_route53domains_registered_domain" "domain" {
  domain_name = var.domain_name
}

#-------------------------------------------------------------------------------
# Let's Encrypt Certificate
#-------------------------------------------------------------------------------

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = aws_route53domains_registered_domain.domain.admin_contact[0].email
}

resource "acme_certificate" "certificate" {
  account_key_pem           = acme_registration.reg.account_key_pem
  common_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]

  dns_challenge {
    provider = "route53"

    config = {
      AWS_PROFILE = var.aws_profile
    }
  }
}

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
    tags = {
      Name = var.instance_name
    }
  }

  user_data = templatefile(
    "scripts/configure-email-oauth2-proxy.yaml",
    {
      timezone                   = var.timezone
      email_oauth2_proxy_version = var.email_oauth2_proxy_version
      email_oauth2_proxy_config  = var.email_oauth2_proxy_config
    }
  )
  user_data_replace_on_change = true

  tags = {
    Name = var.instance_name
  }
}
