#!/usr/bin/env python3
import argparse
import boto3
from botocore.exceptions import ClientError
import configparser
import errno
import json
import os
import re

# Parse command line arguments
parser = argparse.ArgumentParser(description='Transfer OAuth2 tokens between local config file and remote AWS Secrets Manager.')
parser.add_argument('filename')
parser.add_argument('-u', '--upload', action='store_true')
parser.add_argument('-d', '--download', action='store_true')
args = parser.parse_args()

# Verify that exactly one of upload/download was specified
if args.upload == args.download:
    raise ValueError("You must specify either -u/--upload) or -d/--download).")

# Verify config file exists
if not os.path.isfile(args.filename):
    raise FileNotFoundError(errno.ENOENT, os.strerror(errno.ENOENT), args.filename)

# Load local config file
config = configparser.ConfigParser()
config.read(args.filename)
accounts = [s for s in config.sections() if '@' in s]

# Identify accounts with AWS Secret
accounts_aws = [ a for a in accounts if 'aws_secret' in config[a] ]

if not accounts_aws:
    print('No accounts with an "aws_secret" defined in config file.')
else:
    SECRET_KEYS = ['token_salt','access_token','access_token_expiry','refresh_token']

    # Create list of AWS Secrets across all accounts
    secrets_aws = [ config[account]['aws_secret'] for account in accounts_aws ]
    tokens = dict.fromkeys(secrets_aws, {})

    # Load AWS client
    client = boto3.client('secretsmanager')

    if args.upload:
        # Load tokens for each account
        for account in accounts_aws:
            tokens[config[account]['aws_secret']][account] = { key : config[account][key] for key in SECRET_KEYS }

        # Update AWS Secrets
        for secret_id in tokens:
            response = client.put_secret_value(
                SecretId=secret_id,
                SecretString=json.dumps(tokens[secret_id]),
            )
            print(response)
            # XX need to parse put_secret_value errors
        
        print('Tokens uploaded from local config to AWS Secrets Manager.')
    else:
        # Download AWS Secrets
        for secret_id in tokens:
            try:
                get_secret_value_response = client.get_secret_value(
                    SecretId=secret_id
                )
            except ClientError as e:
                # For a list of exceptions thrown, see
                # https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
                raise e

            # Decrypts secret using the associated KMS key.
            tokens[secret_id] = json.loads(get_secret_value_response['SecretString'])

        # Update local config
        for account in accounts_aws:
            for key in SECRET_KEYS:
                config[account][key] = tokens[config[account]['aws_secret']][account][key]

        # Output local config to file
        with open(args.filename, 'w') as config_output:
            config.write(config_output)

        print('Tokens downloaded from AWS Secrets Manager and written to local config.')

    # Debugging
    # print(json.dumps(tokens, indent=4))
