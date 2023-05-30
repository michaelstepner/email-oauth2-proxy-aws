[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)

This repository contains a Terraform configuration for automatically launching and configuring an AWS server to run [simonrob/email-oauth2-proxy](https://github.com/simonrob/email-oauth2-proxy). The server is configured to respond to SMTP queries on port 465 with a TLS certificate from Let's Encrypt. This is not a fully automated process, as detailed in the installation instructions below.

The email-oauth2-proxy application is designed to be run locally, and used with a local email client. This Terraform configuration is designed to create a lightweight cloud server running email-oauth2-proxy, and used with a cloud email provider.

For more information about the Email OAuth 2.0 Proxy, see the README in [simonrob/email-oauth2-proxy](https://github.com/simonrob/email-oauth2-proxy#readme). I will paste the synopsis here:

> Transparently add OAuth 2.0 support to IMAP/SMTP client applications, scripts or any other email use-cases that don't support this authentication method.
> 
> **Motivation and capabilities**
> 
> Email services that support IMAP and/or SMTP access are increasingly requiring the use of OAuth 2.0 to authenticate connections, but not all clients support this method. This script creates a simple local proxy that intercepts the traditional IMAP/SMTP authentication commands and transparently replaces them with the appropriate SASL (X)OAuth 2.0 commands and credentials. Your email client can continue to use the login or auth/authenticate options, with no need to make it aware of OAuth's existence.

## Price of AWS Resources

**THIS SOFTWARE COMES WITH NO WARRANTY OR GUARANTEE REGARDING THE PRICE OF YOUR CLOUD USAGE.** The price you face is determined by AWS, and may be higher or lower depending on your Free Tier availability, email client settings, pricing changes by Amazon, etc.

I am paying ***approximately US$4.55 per month***, based on the prices I observed for my own usage in June 2022:
* $5/year paid upfront for a .link domain registered on Route 53
    * As of 2022-06-11, the cheapest TLD is .click at $3/year *but it has no WHOIS privacy protection*.
    * As of 2022-06-11, the second-cheapest TLD is .link at $5/year **and it has WHOIS privacy protection**.
* $0.50/month for a Route 53 hosted zone
* $3.07/month for a t4g EC2 instance (cheapest instance type)
* $0.16/month for a 2GB EBS volume
* $0.40/month for one secret in AWS Secrets Manager

## Installation

### Pre-requisites:

* An AWS account, with the [AWS CLI](https://aws.amazon.com/cli/) configured on your local machine.
    * You must have an AWS profile configured on your computer with admin access to your account, or at a minimum, sufficient privileges to manage the AWS resources used by this Terraform config.
    * The default profile will be used, although [an alternative profile can be specified](https://github.com/michaelstepner/email-oauth2-proxy-aws/blob/6c31fef7bbc091b1f756ce969fb60bb951786e29/terraform/variables.tf#L5).
* A local installation of [Terraform](https://www.terraform.io/downloads).

### Installation steps:

1. Manually [register a domain using AWS Route 53](https://us-east-1.console.aws.amazon.com/route53/home#DomainRegistration).
    * It may take a few minutes to a few hours for Amazon to complete the domain registration. There may be manual steps involved, such as validating your email address.

2. From the AWS Console, navigate to [Route 53: Hosted Zones](https://us-east-1.console.aws.amazon.com/route53/v2/hostedzones#). Note down the "Hosted zone ID" for your chosen domain, which you will need in step 5.

3. Clone this repository onto your local computer.

4. Make a copy of the `terraform/config_example.tfvars` file, save it under a new name, and fill in the values with your own configuration settings.
    * You can consult the readme in [simonrob/email-oauth2-proxy](https://github.com/simonrob/email-oauth2-proxy#readme) for more details about the `email_oauth2_proxy_config` settings.
    * There are additional settings that can be configured, which may not be detailed in the example file. The full list of config settings is in [variables.tf](https://github.com/michaelstepner/email-oauth2-proxy-aws/blob/main/terraform/variables.tf).
    
5. Using a terminal, navigate to the `terraform` subdirectory of this repo and run the following commands, replacing ALL_CAPS values with your own:
    ```
    terraform init
    terraform import -var-file=YOUR_CONFIG.tfvars aws_route53_zone.primary ZONE_ID_FROM_STEP_2
    ```

6. You are now ready to create the AWS server. Using a terminal, in the `terraform` subdirectory of this repo, run the following command. Terraform will prompt you to review the resources that will be created, then type `yes` to confirm.
    ```
    terraform apply -var-file=YOUR_CONFIG.tfvars
    ```

7. Using a terminal on your local computer, run `ssh -L 8080:127.0.0.1:8080 ec2-user@<PUBLIC_IP OR DOMAIN_FULL_NAME> journalctl --follow -u emailproxy`
    * This will display a live view of the email-oauth2-proxy logs, while also forwarding port 8080 on the server to your local computer for OAuth2 authentication purposes.

8. In your email client, configure SMTP using the server settings:
    * Outgoing SMTP server: `DOMAIN_FULL_NAME`
    * Port: `465`
    * Username: `YOUR_EMAIL_ADDRESS`
    * Password: `ANY_STRING_OF_YOUR_CHOICE`

9. When your email client attempts to connect to the SMTP server, you should see an authentication request appear in the email-oauth2-proxy server log via your SSH session. It will look like the text below. Copy and paste the URL from your terminal into your local browser, then complete the authentication prompts.
    ```
    Email OAuth 2.0 Proxy Local server auth mode: please authorise a request for account your.email@example.com
    Please visit the following URL to authenticate account your.email@example.com: URL
    ```

10. After you've completed the authentication prompts in your local browser, you should see the successful authentication appear in the email-oauth2-proxy server log via your SSH session. It will look like the text below. At this point you can close your local browser tab. Your email client should be able to successfully connect to the SMTP server and send outgoing emails.
    ```
    SMTP ('1.2.3.4', 5678) [ Successfully authenticated SMTP connection - releasing session ]
    ```

11. You can now log out of the remote server by typing `Ctrl`+`c` to end your SSH session. It will continue running the email-oauth2-proxy server in the background.

### Limitations

* Your TLS certificate from Let's Encrypt will expire automatically after 90 days.
* After 60 to 90 days, you can renew the certificate by re-running installation step 6 (`terraform apply ...`).
    * If any settings (such as the TLS certificate) have changed, this will destroy the existing server and create a brand new server.
    * You should not need to re-authenticate (installation steps 7-11), because your OAuth 2.0 tokens are stored persistently in AWS Secrets Manager. Your authentication is not lost when the server is destroyed and re-created.

## Contributing

This code is a work in progress. It has reached a usable state but is not stable, and may receive breaking changes in future versions. Future development will be intermittent: this code was written to fulfill my SMTP-OAuth2 proxy needs, and the current feature set is adequate for me.

If you have a **bug report**, you can create an issue or file a pull request. I'll look into it, time permitting.

If you have a **feature request**, it is unlikely that I will be able to implement it for you. You can create an issue to generate discussion. If you implement a feature, you can file a pull request and I will review it eventually, as time permits. If you're interested in making major additions to the code, I'd be happy to welcome a new maintainer to the project.

### To Do

- [x] [Use certificate](https://github.com/simonrob/email-oauth2-proxy/blob/b26c7b4d25f431e2a1ea12a30667cb9746401211/emailproxy.config#L28) to secure the connection between email client and proxy server
- [x] Add support for storing OAuth2 tokens using a secrets manager (e.g. AWS Secrets Manager) instead of locally, so it persists across servers
- [x] [Automatically launch](https://github.com/simonrob/email-oauth2-proxy/issues/2#issuecomment-839713677) `email-oauth2-proxy` on server via `systemctl`
- [ ] Add support for automatically rotating TLS certificate, which expires automatically after 90 days

## License

All of the files in this repository are open source and can be freely reused, as described in the [0BSD license](https://choosealicense.com/licenses/0bsd/).

## Acknowledgements

This project only exists thanks to [Simon Robinson](https://github.com/simonrob)'s excellent work on [email-oauth2-proxy](https://github.com/simonrob/email-oauth2-proxy). His generous answers in the Issues on that project and implementation of [PR 114](https://github.com/simonrob/email-oauth2-proxy/pull/114) were invaluable in the development of this project.
