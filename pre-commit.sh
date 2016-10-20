#!/bin/bash

# Validate the Terraform configuration of each module.
internal_modules=`ls modules/internal/`

for module in $internal_modules; do
	terraform validate modules/internal/$module
	check_validate_exit=`echo $?`
  if [ "${check_validate_exit}" -ne 0 ]; then
	  echo "There is an issue validating the ${module} module with 'terraform validate'. Fix the errors displayed above in '$(pwd)/modules/internal/${module}' before committing."
	  exit 1
	fi
done