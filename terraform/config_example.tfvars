#-------------------------------------------------------------------------------
# Infrastructure configuration
#-------------------------------------------------------------------------------

# This public key will be in the authorized_keys to allow SSH into the server
ssh_public_key = "** your ssh public key here **"

# List of IP addresses allowed to access SMTP port 465 on the server
# NOTE: to allow access from all IPs, use "0.0.0.0/0"
smtp_allow_list = [
  "127.0.0.1/32",
  "10.1.0.0/32"
]

#-------------------------------------------------------------------------------
# Domain configuration
#-------------------------------------------------------------------------------

# Base domain name, must be manually registered in AWS Route 53
domain_base_name = "example.com"

# Subdomain which will route to the server
domain_full_name = "email.example.com"

#-------------------------------------------------------------------------------
# Server configuration
#-------------------------------------------------------------------------------

# Time zone configured on server, used for logging
# Will default to UTC if left unconfigured
timezone = "America/New_York"

# Config file for email-oauth2-proxy
# For documentation see: https://github.com/simonrob/email-oauth2-proxy
# In your personal .tfvars file:
#   - values in *** three asterisks *** should be manually replaced
#   - values in {{double braces}} should be left as-is, and will be automatically populated on the server
email_oauth2_proxy_config = <<-EOT
[SMTP-1465]
server_address = smtp.office365.com
server_port = 587
starttls = True
local_address = {{private_ip}}
local_certificate_path = fullchain.pem
local_key_path = privkey.pem

[your.office365.address@example.com]
permission_url = https://login.microsoftonline.com/common/oauth2/v2.0/authorize
token_url = https://login.microsoftonline.com/common/oauth2/v2.0/token
oauth2_scope = https://outlook.office365.com/IMAP.AccessAsUser.All https://outlook.office365.com/SMTP.Send offline_access
redirect_uri = http://localhost:8080
client_id = *** your client id here ***
client_secret = *** your client secret here ***
EOT
