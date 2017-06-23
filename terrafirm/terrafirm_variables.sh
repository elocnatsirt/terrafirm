#!/usr/bin/env bash

#######################################
########## PROJECT VARIABLES ##########
#######################################

# Name of your Terraform project
project_name="terrafirm"
# S3 Bucket to store Terraform states
s3_bucket="terraform-states"
# S3 Bucket region to store Terraform states
s3_bucket_region="us-east-1"
# List of valid environments
my_environments=( dev stage prod )


######################################
########### USER VARIABLES ###########
######################################

# AWS Profile to store states
aws_profile="default"
# AWS Credentials file
aws_creds_file="$HOME/.aws/credentials"