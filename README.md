# email-oauth2-proxy-aws
Automated AWS hosting for simonrob/email-oauth2-proxy

## Installation

1. Manually [register a domain using AWS Route 53](https://us-east-1.console.aws.amazon.com/route53/home#DomainRegistration).
    * As of 2022-06-11, the cheapest TLD is .click at $3/year but it has no WHOIS privacy protection.
    * As of 2022-06-11, the second-cheapest TLD is .link at $5/year **and it has WHOIS privacy protection**.

## To Do

- [ ] [Automatically launch](https://github.com/simonrob/email-oauth2-proxy/issues/2#issuecomment-839713677) `email-oauth2-proxy` and configure OAuth2 token without SSHing into the server
- [ ] [Use certificate](https://github.com/simonrob/email-oauth2-proxy/blob/b26c7b4d25f431e2a1ea12a30667cb9746401211/emailproxy.config#L28) to secure the connection between email client and proxy server
