#!/usr/bin/env bash

#########################################
########## TERRAFIRM VARIABLES ##########
#########################################

# Name of your Terraform project
project_name="terrafirm"

# Init options
init_opts="-backend-config=bucket=terrafirm-states -backend-config=region=us-east-1 -backend-config=profile=default -backend-config=shared_credentials_file=$HOME/.aws/credentials"