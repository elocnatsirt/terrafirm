# Terrafirm

Terrafirm is a wrapper around Terraform that enforces what I feel is an ideal 
workflow/structure for a Terraform project.
Terrafirm also provides some helpers that enable you to streamline the writing 
of modules based on the Terrafirm structure.

The basics required to use this script are the folder structure defined in this 
project/README and a 'terrafirm_variables.sh' file with the necessary variables 
in the variables folder relative to your project root. See the helper section 
below for information on how to generate this structure.

# Usage

## Wrapper
**Usage**:
```
./terrafirm.sh (environment) (config) (terraform_command) (extra_args)
```

The wrapper assumes a few things:
- You have the structure defined in this project (see helpers below to generate).
- You are storing states remotely in an S3 backend.
  - The finished path to a remote state file would look like this: 
```s3://$state_bucket/$environment/$config/terrafirm.tfstate```

## Terrafirm Helpers
**Usage**:
```
./terrafirm.sh -(terrafirm_helper_option) (args)
```

**NOTE**
These helpers are all experimental. Do not expect them to work perfectly every 
time. Ideally you would stage any changes within your repository before running 
one of these helpers just in case of any accidental changes.

### Terrafirm Structure Generator

**Terrafirm Variables**
Terrafirm will source a variables file named "terrafirm_variables.sh" from the 
"variables" folder of your project. This will allow you to set variables such 
as your S3 bucket name to store remote states.

When you add a new environment, be sure to add the environment name to the 
'$my_environments' list in this file.

**Folder Structure**
Terrafirm expects a project with this basic structure:
```
| project_root
├── configs
│   └── example_config
│       └──  config.tf
├── modules
│   └── example_module
│       └──  module.tf
├── terrafirm.sh
└── variables
    ├── environments
    │   └── dev
    │       └── common.tfvars
    │       └── example_config.tfvars
    └── terrafirm_variables.sh
```

Terraform provides a native implementation of "environments", which are simply 
arbitrary namespaces that separate out pieces of your state. These environments 
do not currently enforce any kind of project structure or separation of 
variables.

Instead of using these namespaces, you declare an environment with Terrafirm 
simply by adding the environment name to "terrafirm_variables.sh" and creating 
a variables folder within your "terrafirm_root/variables/environments/" 
directory. At runtime, any variable files within this folder will always be 
passed to Terraform in order to override any config defaults with environment 
specific variables. In turn, this pushes you to create environment agnostic 
configs which keeps your environments in line with each other.

### Module Resource Generator
When writing a module, you will need a resource accompanied with a set of 
variables and outputs. The Terraform documentation is straight forward on how 
to configure/write these resources, but the process is generally going to the 
documentation and copying into your own configuration.

To aide writing module resources, pass Terrafirm the "-m" option and a provider 
name combined with a resource name by an underscore, like so: "aws_alb". In this 
example, Terrafirm would create a directory at 
"terrafirm_root/modules/terrafirm_generated_aws_alb" with a file named 
"aws_alb.tf". Example output:

```
# Module Resource
resource "aws_alb" "aws_alb" {
  name = "${var.name}"
}

# Module Outputs
output "id" {
  description = "The ARN of the load balancer (matches arn)."
  value       = "${aws_alb.aws_alb.id}"
}

# Module Variables
variable "name" {
  description = "(Optional) The name of the ALB. This name must be unique within your AWS account, can have a maximum of 32 characters,"
}
```

**NOTE**
To re-iterate on the experimental nature of these helpers, this generator is far 
from perfect. This generator does not interpret block variables, differentiate 
string variables from lists, and if Hashicorp were to update their documentation 
it would break instantly. It is good for getting a quick and dirty representation 
of what your module/resource should look like.

### Custom Module Variable Generator
After writing a module, you have to define the variables that you are passing 
somewhere. Instead of doing this by hand, pass Terrafirm the "-v" option and a 
module directory and let it generate a variables file for you.

## Testing and Validation
There is a pre-commit hook script in the root of this directory. To enable it 
locally, run this command from the project root:
```
ln -s pre-commit.sh .git/hooks/pre-commit
```