#!/bin/bash

# Validate the Terraform configurations
configs=`ls configs`

for config in $configs; do
	terraform validate configs/$module
	check_validate_exit=`echo $?`
  if [ "${check_validate_exit}" -ne 0 ]; then
	  echo "There is an issue validating the ${config} configuration with 'terraform validate'. Fix the errors displayed above in '$(pwd)/configs/${config}' before committing."
	  exit 1
	fi
done