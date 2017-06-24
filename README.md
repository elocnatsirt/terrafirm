# Terrafirm
*Terrafirm* is my vision of an ideal Terraform project structure/workflow.

By nature, the wrapper is very strict and requires your project to have a very 
defined structure. See the helper section below for information on how to 
generate this structure.

## Environments
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

## Variables
Terrafirm will source a variables file named "terrafirm_variables.sh" from the 
"terrafirm_files" folder of your project. This will allow you to set variables 
such as your S3 bucket name to store remote states. You can generate this file 
with sane defaults using the 'Terrafirm Structure Generator' helper.

### Secret Variables
Terrafirm gives you the option to have a secret variables file per environment. 
These files are located in the standard environment specific variables folder, 
and currently have a static name of ```secret.tfvars(.encrypted)```. These secret 
files automatically get decrypted at runtime and then re-encrypted after if they 
exist. It is worth noting that the secret variables file is the last var-file 
passed to Terraform.

To use the secret variable feature, all you have to do is add your public GPG key 
to a file named ```(terrafirm_root)/terrafirm_files/public_keys/(public_key_id)```. 
See the 'Terrafirm Helpers' section below for various secret helpers that 
enable you to easily encrypt and edit your secrets.

**NOTE** It is important to use the key's ID as the filename when adding GPG keys 
to the project. When encrypting secrets, Terrafirm uses the names of these files 
to include as GPG recipients after importing to the local keychain.

## Wrapper
**Usage**
```
./terrafirm (environment) (config) (terraform_command) (extra_args)
```

The wrapper assumes a few things:
- You have the structure defined in this project (see helpers below to generate).
- You are storing states remotely in an S3 backend.
  - The finished path to a remote state file would look like this: 
```s3://$state_bucket/$environment/$config/terrafirm.tfstate```

### Terrafirm Helpers
**Usage**
```
./terrafirm -(terrafirm_helper_option) (args)
```

**NOTE**
These helpers are all experimental. Do not expect them to work perfectly. Ideally 
you would stage any changes within your repository before running one of these 
helpers just in case of any accidental changes.

### Terrafirm Structure Generator
Terrafirm requires a specific project structure. This helper will generate the 
basic structure in your project:

```
| project_root
├── configs
├── modules
├── terrafirm_files
│   ├── public_keys
│   └── terrafirm_variables.sh
├── terrafirm
└── variables
    └── environments
```

See this project's structure for a more detailed layout.

### Secret Variables File Editor
Working with secrets in Terrafirm requires you to have a file named ```secret.tfvars(.encrypted)```` 
in your environment variables folder. If this file is present, Terrafirm will 
automatically decrypt it at runtime and then re-encrypt it after Terraform finishes 
running.

You can create this encrypted file in one of two ways: by calling this helper and 
letting it create this file for you (you will have a chance to edit it as well) 
or creating a ```variables/environments/(env)/secret.tfvars``` file with your 
secrets and running Terrafirm as you would normally.

**NOTE** This is a variables file by nature. It has not been tested with any 
other Terraform specific configuration. However, you could in theory include 
commented sections of other secrets such as Terraform user AWS keys. In the 
future, the idea is to expand secrets to Terraform modules/configurations and/or 
other types of secrets.

**NOTE** Due to the nature of PGP, Git, and how the script is currently written, 
whenever you run Terrafirm these encrypted files will change, prompting Git to 
think it has uncommitted changes even though the "content" hasn't changed. Be 
careful when commiting/editing these files and be aware of your changes. My advice 
is to commit any secret file as soon as you make a content change. This will be 
fixed in the near future.

### Re-Encrypt Secret Variables File
The secret variable files in your project are encrypted with any public keys that 
are included in the ```terrafirm_files/public_keys``` folder. When adding a new 
member to your team, in order to work with secrets they will need to generate 
their own GPG keypair and add their public key to the project. Once added, an 
existing team member can re-encrypt the secret files with this helper allowing 
them to decrypt the Terrafirm files at runtime. The added benefit is that if you 
remove a team member or recycle a keypair, their access will be automatically 
removed the next time the secrets are encrypted.

**NOTE** GPG keys that use a passphrase will be prompted to enter it during the 
Terrafirm runtime. If you are using Terrafirm in an automated fashion, use a GPG 
key that does not have a passphrase.

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