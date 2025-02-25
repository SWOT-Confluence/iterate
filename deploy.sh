#!/bin/bash
#
# Script to create a zipped deployment package for a Lambda function and deploy
# AWS infrastructure.
#
# Command line arguments:
# [1] app_name: Name of application to create a zipped deployment package for
# [2] s3_state_bucket: Name of the S3 bucket to store Terraform state in (no need for s3:// prefix)
# [3] profile: Name of profile used to authenticate AWS CLI commands
# 
# Example usage: ./delpoy.sh "my-app-name" "s3-state-bucket-name" "confluence-named-profile"

APP_NAME=$1
S3_STATE=$2
PROFILE=$3

# Zip script
zip $APP_NAME.zip $APP_NAME.py
echo "Created: $APP_NAME.zip."

# Deploy terraform
terraform init -reconfigure -backend-config="bucket=$S3_STATE" -backend-config="key=enable-renew.tfstate" -backend-config="region=us-west-2" -backend-config="profile=$PROFILE"
terraform apply -var-file="conf.tfvars" -auto-approve
