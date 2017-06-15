#!/usr/bin/env bash

# Written by: https://github.com/elocnatsirt
# Terrafirm is a wrapper script around Terraform that enforces a specific 
# configuration structure for your team.

SCRIPT=`basename ${BASH_SOURCE[0]}`
NORM=`tput sgr0`
BOLD=`tput bold`
REV=`tput smso`

function HELP {
  echo -e \\n"Help documentation for ${BOLD}${SCRIPT}.${NORM}"\\n
  echo -e "${REV}Basic usage:${NORM} ${BOLD}$SCRIPT (environment) (config) (cmd)${NORM}"\\n
  echo "Command line options:"
  echo -e "${REV}\$1${NORM} (Required) TF environment name. Will reference an environment specific variable file of the same name."
  echo -e "${REV}\$2${NORM} (Required) TF configuration name to manage."
  echo -e "${REV}\$3${NORM} (Required) Command for Terraform to run against specified environment and configuration."
  echo -e "${REV}\$4${NORM} (Optional) Extra args to pass to Terraform."
  echo -e "Example: ${BOLD}$SCRIPT dev vpc plan -var 'map={ override = "yes" }'${NORM}"\\n
  exit 1
}

NUMARGS=$#
if [ $NUMARGS -le 2 ]; then
  HELP
fi

environment=$1
config=$2
tf_cmd=$3
extra_tf_args=$4

# Source Terrafirm variables
source variables/terrafirm_variables.sh

# Make sure the user is in the root directory of the terraform repo.
if [ "${PWD##*/}" != "${project_name}" ]; then
  echo "You need to be in the root of the Terraform project."
  exit 1
fi

# Check the environment argument to see if it calls a real environment.
if [[ " ${my_environments[*]} " != *" ${environment} "* ]]; then
  echo "You need to specify a real environment."
  exit 1
fi

# Check the config to make sure we actually specified one.
if [ "${config}" == "" ]; then
  echo "You need to specify a configuration to manage."
  exit 1
else
  if [ ! -d "configs/${config}" ]; then
    echo "Are you sure this configuration exists? Cannot find it at $(pwd)/configs/${config}/"
    exit 1
  fi
  cd configs/${config}
fi

# Validate the Terraform configuration before running
if ! terraform validate; then
  echo "${REV}Fix the validation errors above, then re-run this script.${NORM}"
  exit 1
fi

# Initialize the Terrafirm remote state and gather modules
terraform init -input=false -get=true -backend=true -backend-config="key=${environment}/${config}/terrafirm.tfstate'" -backend-config="bucket=${s3_bucket}" -backend-config="region=${s3_bucket_region}" -backend-config="profile=${aws_profile}" -backend-config="shared_credentials_file=${aws_creds_file}"

# Gather variable files
variable_files=""
for filename in "../../variables/environments/${environment}/*"; do
  for file in $filename; do
    variable_files=$variable_files" -var-file $file"
  done
done

# Run the Terraform command specified
terraform ${tf_cmd} ${variable_files} ${extra_tf_args}

echo -e \\n"${REV}Notice:${NORM} Finished Terraforming '${environment} ${config}'"