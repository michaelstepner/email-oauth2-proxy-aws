#-------------------------------------------------------------------------------
# Domain (must be already registered in AWS Route 53)
#-------------------------------------------------------------------------------

resource "aws_route53domains_registered_domain" "domain" {
  domain_name = var.domain_base_name
}

resource "aws_route53_zone" "primary" {
  name = var.domain_base_name
}

resource "aws_route53_record" "app_server" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain_full_name
  type    = "A"
  ttl     = "300"
  records = [aws_eip.app_server.public_ip]
}

#-------------------------------------------------------------------------------
# AWS Secrets Management
#-------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "oauth2_tokens" {
  name                    = "email_oauth2_proxy_tokens"
  recovery_window_in_days = 7
}

resource "aws_iam_user" "user_email_oauth2_proxy" {
  name = "email_oauth2_proxy"
}

resource "aws_iam_access_key" "user_email_oauth2_proxy" {
  user = aws_iam_user.user_email_oauth2_proxy.name
}

resource "aws_iam_user_policy" "oauth2_tokens_readwrite" {
  name = "email_oauth2_tokens_readwrite"
  user = aws_iam_user.user_email_oauth2_proxy.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
        ]
        Resource = aws_secretsmanager_secret.oauth2_tokens.arn
      },
    ]
  })
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
  common_name               = aws_route53domains_registered_domain.domain.domain_name
  subject_alternative_names = ["*.${aws_route53domains_registered_domain.domain.domain_name}"]

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

resource "tls_private_key" "ssh_host_ed25519_key" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "ssh_login" {
  key_name   = var.aws_resource_name
  public_key = var.ssh_public_key
}

resource "aws_eip" "app_server" {
  instance = aws_instance.app_server.id
  vpc      = true
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
      Name = var.aws_resource_name
    }
  }

  user_data = templatefile(
    "server-cloud-config.yaml",
    {
      timezone                   = var.timezone
      email_oauth2_proxy_version = var.email_oauth2_proxy_version
      email_oauth2_proxy_config  = var.email_oauth2_proxy_config
      cert_fullchain             = "${acme_certificate.certificate.certificate_pem}${acme_certificate.certificate.issuer_pem}"
      cert_privkey               = acme_certificate.certificate.private_key_pem
      ssh_host_ed25519_privkey   = tls_private_key.ssh_host_ed25519_key.private_key_openssh
      ssh_host_ed25519_pubkey    = tls_private_key.ssh_host_ed25519_key.public_key_openssh
    }
  )
  user_data_replace_on_change = true

  tags = {
    Name = var.aws_resource_name
  }
}
