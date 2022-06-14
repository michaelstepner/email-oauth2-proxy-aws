#-------------------------------------------------------------------------------
# Infrastructure configuration
#-------------------------------------------------------------------------------

variable "aws_profile" {
  description = "Profile for AWS access"
  default     = "default"
}
variable "aws_region" {
  description = "Region for AWS resources"
  default     = "us-east-1"
}
variable "aws_availability_zone" {
  description = "Availability zone for AWS resources"
  # Note: instance type (t4g.nano) is supported in us-east-1a, us-east-1b, us-east-1c, us-east-1d, us-east-1f.
  default = "us-east-1a"
}
variable "aws_resource_name" {
  description = "Name of AWS resources"
  default     = "email-oauth2-proxy"
}
variable "instance_type" {
  description = "Type of EC2 instance"
  default     = "t4g.nano"
}
variable "volume_size" {
  description = "Space in GB on EC2 instance root volume"
  default     = "2"
}
variable "ssh_public_key" {
  description = "Public key with SSH access to the EC2 instance"
}
variable "smtp_allow_list" {
  description = "List of IPs allowed to access SMTP server"
}

#-------------------------------------------------------------------------------
# Domain configuration
#-------------------------------------------------------------------------------

variable "domain_base_name" {
  description = "Domain name that is already registered with AWS"
}
variable "domain_full_name" {
  description = "Subdomain that will route to email-oauth2-proxy server"
}

#-------------------------------------------------------------------------------
# Server configuration
#-------------------------------------------------------------------------------

variable "timezone" {
  description = "Timezone to set as default on server"
  default     = "UTC"
}
variable "email_oauth2_proxy_version" {
  description = "Branch or tag name to checkout from simonrob/email-oauth2-proxy Github repo"
  default     = "main"
}
variable "email_oauth2_proxy_config" {
  description = "Config file for email-oauth2-proxy to be stored as personal.config"
}
