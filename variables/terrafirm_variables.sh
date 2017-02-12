#!/usr/bin/env bash

########################################
############ USER VARIABLES ############
########################################

# Name of your Terraform project
project_name="terrafirm"

# S3 Bucket to store Terraform states
s3_bucket="terraform-states"

# AWS Profile to store states
aws_profile="default"

# List of valid environments
my_environments=( dev stage prod )