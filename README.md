# Terrafirm

Terrafirm is a wrapper around Terraform that enforces what I feel is an ideal 
workflow/structure for a Terraform project.

[Terraform Docs](https://www.terraform.io/docs/index.html)

## Project Structure
Terrafirm expects a project with this basic structure:
```
| project_root
├── configs
│   └── config
│       ├── config.tf
├── terrafirm.sh
└── variables
    ├── environments
    │   └── environment.tfvars
    └── terrafirm_variables.sh
```

Terraform provides a native implementation of "environments", which are simply 
arbitrary namespaces that separate out pieces of your state. These environments 
do not currently enforce any kind of project structure or separation of 
variables.

Instead of using these namespaces, Terrafirm declares environments simply by 
using named variable files. At runtime, these files will always be passed to 
Terraform in order to override any defaults with environment specific 
configuration. In turn, this pushes you to create environment agnostic configs 
which keeps your environments in line with each other.

### Wrapper
**Basic Usage**:
```
./terrafirm.sh (environment) (config) (terraform_command)
```

The wrapper assumes a few things:
- You have the structure defined above.
- You are storing states remotely in an S3 backend.
  - The finished path to a remote state file would look like this: 
```s3://$state_bucket/$environment/$config/terrafirm.tfstate```

#### Terrafirm Variables
Terrafirm will source a variables file named "terrafirm_variables.sh" from the 
"variables" folder of your project. This will allow you to set variables such 
as your S3 bucket name to store remote states.

When you add a new environment, be sure to add the environment name to the 
$my_environments list in this file.

## Testing and Validation
There is a pre-commit hook script in the root of this directory. To enable it locally,
run this command from the project root:
```
ln -s pre-commit.sh .git/hooks/pre-commit
```