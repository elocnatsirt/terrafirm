#!/usr/bin/env bash

# Written by: https://github.com/elocnatsirt
# Terrafirm is a wrapper script around Terraform that enforces a specific 
# configuration structure for your team.
# Terrafirm also provides some helpful functions that allow you to streamline 
# writing and validating your Terraform modules and configurations.

# Script Help
SCRIPT=`basename ${BASH_SOURCE[0]}`
NORM=`tput sgr0`
BOLD=`tput bold`
REV=`tput smso`

function help {
  echo -e \\n"${REV}Basic usage:${NORM} ${BOLD}$SCRIPT (environment) (config) (cmd) (optional_args) ${NORM}"
  echo -e "${REV}Advanced usage:${NORM} ${BOLD}$SCRIPT -(terrafirm_helper_option) (args) ${NORM}"\\n
  echo -e "${BOLD}Basic command line options:${NORM}"
  echo -e "${REV}\$1${NORM} (Required) TF environment name. Will reference an environment specific variable file of the same name."
  echo -e "${REV}\$2${NORM} (Required) TF configuration name to manage."
  echo -e "${REV}\$3${NORM} (Required) Command for Terraform to run against specified environment and configuration."
  echo -e "${REV}\$4${NORM} (Optional) Extra args to pass to Terraform."
  echo -e "Example: ${BOLD}$SCRIPT dev vpc plan -var 'map={ override = "yes" }'${NORM}"\\n
  echo -e "${BOLD}Terrafirm helper options:${NORM}"
  echo -e "${REV}-m${NORM} Generates a module based on the Terraform provider and resource provided."
  echo -e "  - Argument must be in the form of 'provider_resource'."
  echo -e "  - Example: ${BOLD}$SCRIPT -m aws_alb ${NORM}"
  echo -e "${REV}-s${NORM} Generates a basic Terrafirm directory structure based on the directory you are currently in."
  echo -e "  - Example: ${BOLD}$SCRIPT -s ${NORM}"
  echo -e "${REV}-v${NORM} Generates a Terraform variable file based on the Terrafirm module path provided."
  echo -e "  - Ignores files with the name 'variables.tf','outputs.tf', and files with the '.tfvars' extension."
  echo -e "  - Example: ${BOLD}$SCRIPT -v my_custom_modules/vpc ${NORM}"
  exit 1
}

# Terrafirm Helper Functions
function generate_structure {
  mkdir -p configs
  mkdir -p modules
  mkdir -p variables/environments
  tee "variables/terrafirm_variables.sh" <<EOF > /dev/null
#!/usr/bin/env bash
project_name="terrafirm"
s3_bucket="terraform-states"
s3_bucket_region="us-east-1"
my_environments=( )
aws_profile="default"
aws_creds_file="\$HOME/.aws/credentials"
EOF
  echo -e "${BOLD}Notice:${NORM} Generated Terrafirm directory structure at ${PWD}"
  exit
}

function generate_variables {
  cd modules/$1 || help
  files=`ls | grep -v variables | grep -v outputs | grep -v .tfvars`
  cat $files | grep '${var.' | sed 's/.*${var./var./g;s/}.*//g;s/ [!@#\$%^&*()].*//g' | sort | uniq | sed 's/var./variable "/g;s/$/" {}/g' >> generated_variables.tfvars
  echo -e "${BOLD}Notice:${NORM} Module variable file generated at ${PWD}/generated_variables.tf"
  exit
}

function generate_module {
  provider=`echo $1 | sed 's/_.*//'`
  resource=`echo $1 | sed 's/^[^_]*_//'`
  new_dir="modules/terrafirm_generated_${provider}_${resource}"
  url="https://www.terraform.io/docs/providers/${provider}/r/${resource}.html"
  page=`curl -s ${url}`
  variables=`echo -e "${page}" | sed '1,/<p>The following arguments are supported/d;/<h2 id="attributes-reference">/,$d' | grep '<a name=' | sed 's/.*"><code>//;s/<\/code><\/a>//;s/<code>//g;s/<\/code>//g'`
  outputs=`echo -e "${page}" | sed '1,/<p>The following attributes are exported/d;/<h2/,$d' | grep '<a name=' | sed 's/.*"><code>//;s/<\/code><\/a>//;s/<code>//g;s/<\/code>//g' | sed 's/^/output "/;s/ [-=] /" {  description = "/;s/$/"}/'`

  echo -e "${BOLD}Notice:${NORM} Generating module from ${url}"
  mkdir -p $new_dir || exit
  cd $new_dir || exit
  echo -e "# Module Resource" > ${provider}_${resource}.tf
  echo -e "resource \"$1\" \"$1\" {" >> ${provider}_${resource}.tf
  while read -r var; do
    short_var=`echo -e "${var}" | sed 's/ [-=] .*//' | tr -d '\n'`
    echo -e "  ${short_var} = \"\${var.$short_var}\"" >> ${provider}_${resource}.tf
  done <<< "${variables}"
  echo -e "}" >> ${provider}_${resource}.tf

  echo -e \\n"# Module Outputs" >> ${provider}_${resource}.tf
  while read -r line; do
    id=`echo -e "${line}" | sed 's/output "//;s/".*//' | tr -d '\n'`
    echo -e "${line}" | sed $'s/{/{\\\n/g;s/}/\\\n}/g' | sed "s,},  value       = \"\${$1.$1.$id}\"}," | sed 's/}"}/}"\'$'\n}/' >> ${provider}_${resource}.tf
  done <<< "${outputs}"

  echo -e \\n"# Module Variables" >> ${provider}_${resource}.tf
  echo -e "${variables}" | sed 's/^/variable "/;s/ [-=] /" {  description = "/;s/$/"}/' | sed $'s/{/{\\\n/g;s/}/\\\n}/g' >> ${provider}_${resource}.tf
  echo -e "${BOLD}Notice:${NORM} Module file generated at ${PWD}/${provider}_${resource}.tf"
  exit
}

# Interpret options if supplied
while getopts "hm:sv:" opt; do
  case "$opt" in
  m)
      generate_module "$OPTARG"
      ;;
  s)
      generate_structure
      ;;
  v)
      generate_variables "$OPTARG"
      ;;
  h)
      help
      ;;
  \?)
      help
      ;;
  esac
  exit
done
shift $((OPTIND-1))

# Gather and validate arguments
environment=$1
config=$2
tf_cmd=$3

NUMARGS=$#
if [ $NUMARGS -le 2 ]; then
  help
elif [ $NUMARGS -gt 3 ]; then
  while shift && [ -n "$3" ]; do
    extra_tf_args="${extra_tf_args} $3"
  done
fi

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

# Remove local .terraform directory before running to prevent environment conflicts
rm -rf .terraform/

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