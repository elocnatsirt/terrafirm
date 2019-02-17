# Terrafirm
*Terrafirm* is my vision of how a Terraform project should be managed.

## Motivation
[Terraform](https://terraform.io) is, in my opinion, the best tool available for 
managing your infrastructure. Because of the broad range of providers available, 
you can provision everything from your local environment to your production 
environment spanning different cloud providers in one tool/project. I would go as 
far as to say that it's the Jenkins of infrastructure automation tools, but that 
might scare some people off.

Terraform offers you a lot of freedom. A downside to this is that there is no set 
project structure, so often users begin with a simple configuration and apply it 
to different environments. This often grows into large monolithic state files 
which become very difficult to manage, especially if you only want to make small 
changes to a single resource.

Early on I decided I wanted to split out different resources of a project into 
reusable manageable chunks of code. Terraform's native implementation of 
environments, now called workspaces, do not enforce the strict separation of state, 
variables, or configs in a concise manner. Another downside is that Terraform 
currently does not [allow interpolation when configuring a backend](https://github.com/hashicorp/terraform/issues/17288). Enter Terrafirm.

---
## Terrafirm Project Structure
Terrafirm requires your code to live in specific locations relative to the 
project root. As such, your project should mirror the following basic structure:
```
.
├── configs
├── terrafirm_files
│   └── terrafirm_variables.sh
├── terrafirm
└── variables
    └── environments
```

### Configs
A Terraform config consists of a set of resources that represent a logical set 
of infrastructure. Terrafirm encourages you to split these configs out into 
smaller manageable chunks that make sense for your team.

* Create a config in Terrafirm by creating a folder under the `terrafirm_root/configs/` 
directory with your config name. 

#### Roles - *IN PROGRESS*
* Create a role in Terrafirm by creating a folder under the `terrafirm_root/configs/` 
directory with your role name and a file called `default.role` with a list of 
configs you want to manage via that role.

### Environments
Environments in Terrafirm represent logical separations of state files and 
variables. Currently environments are declared by creating a named variables 
folder in your project. At runtime, any variable files within this folder will 
be passed to Terraform in order to override any config or common defaults with 
environment specific variables.

* Create an environment in Terrafirm by creating a folder under the 
`terrafirm_root/variables/environments/` directory with your environment name.

> **NOTE:** In the future, Terrafirm will allow for runs for "dynamic" 
environments that do not require overrides.

### Variables
Generally there are a set of common variables you will want to share across a 
team regardless of environment or config. You may also want to set common 
variables across an environment regardless of config. A config sets its own 
default values, but you may want to override those per environment. Terrafirm 
covers all of these cases.

Whereas the variables `${env}` and `${config}` correspond respectively to the 
Terrafirm environment and config you want to manage:

* To set common variables across your project, create the file 
`terrafirm_root/variables/common.tfvars` and populate it with the desired vars.

* To set/override common variables across a specific environment, create the file 
`terrafirm_root/variables/environments/${env}/common.tfvars` and populate it with 
the desired vars.

* To set/override default config variables for a specific environment, create a 
file named `terrafirm_root/variables/environments/${env}/${config}.tfvars` and 
populate it with the desired vars.

---
## Terrafirm Wrapper
**Basic Usage**
```
./terrafirm ${environment} ${config} ${terraform_command} ${extra_args}
```

* `${environment}` is the Terrafirm environment (described above) to manage.

* `${config}` is the Terraform config (described above) to manage.

* `${terraform_command}` is the normal Terraform command to execute against the 
given environment and config. This would generally be one of `plan`, `apply`, or 
`destroy`.

* `${extra_args}` are any extra arguments to pass to the Terraform command you 
are executing. Examples would be targeting resources or overriding variables.

> **NOTE:** Terraform commands other than those listed above may work with 
Terrafirm, however it is not guaranteed. If you want to manage Terraform state, 
first run Terrafirm with the `plan` command and then `cd` into the config you want 
to manage and run your one off `terraform` command as you would normally. 
Terrafirm initializes your remote state inside the given config when it runs 
and does not clear it until the next run, allowing you to manage it manually if 
necessary.

##### Here's what happens when Terrafirm runs:

1. Terrafirm checks if you're trying to use a helper.
  - If it detects a helper argument, it executes that function.
  - If it does not detect a helper argument, it checks to ensure you are providing 
  the minimum number of arguments required.
2. Terrafirm sources the `terrafirm_files/terrafirm_variables.sh` file.
3. Terrafirm checks that you are passing arguments correctly:
  - It first ensures you are in the project root.
  - It checks that you provided a valid environment to manage.
  - It checks that provided a valid config to manage.
    - It `cd`s into the directory of the config.
    - If the config provided is a role, Terrafirm manages all the configs listed.
4. Terrafirm runs and does the following:
  - Removes the local state file at 
  `terrafirm_root/configs/${config}/.terraform/terraform.tfstate`.
  - Initializes the Terraform backend/state and gathers modules.
  - Gathers variables files for the provided environment.
  - Validates the configuration with gathered variables.
  - Runs Terraform with the provided command sourcing all the variables files 
  from the given environment.
    - Extra arguments are included if given. Note that extra arguments are 
    provided after variables in order to support manual overrides.

#### Wrapper Settings
Terrafirm will source a variables file named "terrafirm_variables.sh" from the 
"terrafirm_files" folder of your project. This will allow you to set variables 
such as your project name and `init_opts` for backend configuration. You can 
generate this file with sane defaults using the `generate_structure` helper 
detailed below.

#### Helpers
**Usage**
```
./terrafirm ${terrafirm_helper} ${args}
```

**NOTE:**
These helpers are all experimental. Stage any changes within your repository 
before running helpers just in case of any accidental overwrites.

##### Terrafirm Structure Generator (generate_structure)
Terrafirm requires a specific project structure as described above. Pass Terrafirm 
the `generate_stucture` argument to generate this basic structure in the root 
directory of your project:

```
.
├── configs
├── modules
├── terrafirm_files
│   └── terrafirm_variables.sh
└── variables
    └── environments
```

##### Module Skeleton Generator (generate_module)
To streamline creating modules, pass Terrafirm the `generate_module` argument 
and the path at which you want to create the new module. This will generate a 
module at the given path with this structure:

```
.
└── modules
    └── ${module_path}
        └── main.tf
        └── variables.tf
        └── outputs.tf
        └── README.md
        └── LICENSE
```

##### Module Variable Generator (generate_variables)
After writing a module, you have to define the variables that you are passing 
somewhere. Instead of doing this by hand, pass Terrafirm the `generate_variables` 
argument along with a path to a module and it will generate a variable file named 
`generated_variables.tfvars` inside your module directory.

---
## Detailed Example Structure
For a more detailed usage of Terrafirm, let's examine the structure of this repo:
```
.
├── common
│   └── aws_provider.tf
├── configs
│   ├── another_example_config
│   │   ├── aws_provider.tf -> ../../common/aws_provider.tf
│   │   ├── config.tf
│   │   └── variables.tf
│   ├── example_config
│   │   ├── aws_provider.tf -> ../../common/aws_provider.tf
│   │   └── config.tf
│   └── role_template
│       ├── default.tfrole
│       └── prod-west.tfrole
├── modules
│   └── example_module
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── terrafirm
├── terrafirm_files
│   └── terrafirm_variables.sh
└── variables
    ├── common.tfvars
    └── environments
        ├── dev
        │   └── config_template.tfvars
        ├── prod
        │   ├── common.tfvars
        │   └── config_template.tfvars
        └── prod-west
            └── common.tfvars
```

### Common
The idea behind the common folder is to house common pieces of configuration 
that would normally be duplicated in configs. This could be, but isn't limited 
to, backend and provider configurations. The `aws_provider.tf` file uses AWS 
as the provider and backend:
```
variable "aws" {
  type    = "map"
  default = {
    region           = "us-east-1"
    aws_profile_name = "default"
  }
}

provider "aws" {
  region  = "${var.aws["region"]}"
  profile = "${var.aws["aws_profile_name"]}"
}

terraform {
  backend "s3" {}
}
```
While Terraform doesn't allow interpolation in the backend config, it does allow 
interpolation in the provider configuration. This means that we can set a common 
backend and provider with common defaults that we can override as necessary.

### Configs
At its core, a config is just one or more resources separated via code from 
another resource or set of resources. When creating a config for your 
environment, especially migrating existing infrastructure into Terraform,
it's easy to just start throwing everything into one large file. This isn't a 
big deal if you have a small team or a relatively small amount of simple 
resources; however as your team and infrastructure scale, manging everything in 
one config becomes difficult due to common issues like state drift. Because of 
how Terraform reconciles state, it is very easy to make a small manual change and 
end up having more state changes than you expected. Coupling that with the fact 
that Terraform output by default is not the prettiest, this makes manging large 
monolithic configs too difficult unless your environment is entirely automated 
(which is a great dream to have).

Breaking down your configuration into smaller manageable chunks allows you to 
manage only what you need to and keep drift to a minimum. Terrafirm doesn't 
enforce any specific configuration size, it just promotes the ability to break 
them out in a more manageable way.

**Take an application environment** that has a backend and a frontend component. The 
frontend is made up of three client services while the backend is made up of ten 
platform services. You have a few options here:

* Make a config containing the whole application.
  * This could be manageable depending on how modularized your config is. Your 
  client and platform configs must update together to ensure no state drift.
* Make separate configs for the client and platform services.
  * **_This is my preferred setup_**, allowing you to manage both client and platform 
  configurations independently of each other.
* Make separate configs for each client and platform service individually.
  * This is a little bit overkill, especially if the majority of your services 
  deploy in a similar manner.

In the scenario where you need to add a database, or S3 buckets that contain 
permanent data; would you want to manage those at the same time as your client 
and platform applications? Even if you said yes in the best case scenario of a 
fully automated environment, you will generally end up targeting resources and 
introducing some form of drift into your environment.

**Take a look** at the config `another_example_config`. There are three files in 
this config:
* `aws_provider.tf` which is a symlink to `../common/aws_provider.tf`
* `config.tf` which contains the main code for the config
* `variables.tf` which contains any default variables for the config

A config can contain any number of `.tf` files with any prefix. Breaking 
resources out into named config files for organization in large projects is 
encouraged (an example would be an `instances.tf` file and a `security_groups.tf` 
file).

As explained above, symlinking the `aws_provider.tf` file from the common folder 
allows us to set a default provider and backend that can be shared across all 
configs. You could include common references to base images, global states, etc.
* _Be aware_ that changing this file will affect all configurations. Ideally 
this file doesn't change much.

#### Roles
In the previous example of an application environment where you have split out 
your configuration into manageable chunks, these chunks still make up a single 
application environment. As such, you occasionally will need to manage every 
single one of these configurations at once, for instance to create a new 
environment.

Roles allow you to manage multiple Terraform configurations at once in the same 
environment. This means that you could define a role to manage your entire 
environment at will while still keeping all the pieces of your infrastructure 
logically separated out in configs.

**Take a look** at the config `example_role`. A role is defined as a config by 
design; I made this decision because I wanted to ensure that nobody could name a 
config the same as a role. This also allows you to override the role per 
environment if desired. `example_role` contains two files, `default.tfrole` and 
`prod-west.tfrole`. Respectively they contain the following:
```
example_config
another_example_config
```
```
example_config
```
In this example, if you called `example_role` as any environment other than 
`prod-west`, it would run the two configs `example_config` and `another_example_config`. 
However, for `prod-west` we override this default runlist and only run the 
`example_config`. A scenario in which this could be useful is you have a set of
application configs that create an environment, but you have a specific config 
that only needs to run in preprod environments or in replicated regions. As such, 
you can override the default runlist as desired per environment.

### Modules
Modules are packages of Terraform configurations managed as a group. All configs 
are modules, but not all modules are configs. A config, where you're running the 
normal terraform commands, is considered a `root module`. This is why Terrafirm 
separates configs and modules in different sections of the project. Another 
separation between configs and modules I would make is that configs tend to be 
more of "internal" code that consume more generic modules that you might share 
outside of your organization; however you should still create modules for internal 
usage where applicable.

**Remembering** the previous example, we had a client and platform config that 
each consisted of multiple services. Chances are that all the client and platform 
services both follow similar (but individual respective to configs) deployment 
patterns. You could create a `platform_service_module` directory under the 
`terrafirm_project_root/modules/internal/` directory and create a module for the 
platform services. For each service in the config, you could call this module 
to create the necessary resources for that server. In addition, this allows you 
to target a specific service in the config for fine grained management.
```
├── modules
│   ├── external
│   │   ├── aws
│   │   │   └── aws_load_balancer
│   │   └── azure
│   │       └── azurerm_lb
│   └── internal
│       ├── client_service
│       └── platform_service
```
Separate modules in a way that makes sense for your project. When referencing a 
module, you supply the exact path to the module (if locally sourced) which means 
that you can organize them however you want.

### Terrafirm and Terrafirm_Files
Terrafirm needs some basic information in order to setup the backend correctly 
and ensure you're working in the right project. The `terrafirm_files` folder in 
the project root contains the `terrafirm_variables.sh` file. This file contains 
the following:
```
#!/usr/bin/env bash

# Name of your Terraform project
project_name="terrafirm"

# Init options
init_opts="-backend-config=..."
```
While Terrafirm enforces a basic project structure, it also tries to allow as 
much freedom as possible within that structure. However it does not fit all use 
cases, backends, or projects. You might need to make small modifications to script 
functions to tweak them for your project. YMMV.

### Variables
Most configs and modules will set default variables, but occasionally you will 
want to override these per environment. Generally you will want to apply these 
variables every time you apply a configuration. If these variable files are in 
separate folders than your configuration for overrides, you have to pass them 
manually to the Terraform command.

When running Terrafirm against a given environment, values for that environment 
are automatically pulled in at runtime. Terrafirm also pulls a set of common 
variables if they exist. The load order of variables is as follows:
1. `TF_VAR_` environment variables.
2. Default module variables.
3. Default config variables.
4. Common project variables.
5. Environment specific variables.
6. CLI variable overrides.

#### Environments
Terraform provides a native implementation of "workspaces", which are state 
separated namespaces within the same config/backed that allow you to work without 
affecting another namespace. These environments do not currently enforce any kind 
of project structure or separation of variables.

In Terrafirm, you declare an environment by creating a named folder under the 
`terrafirm_project_root/variables/environments` folder. This design choice was 
made as most environments will require some form of variable override when apply 
a config. As mentioned previously in the project, future improvements will allow 
for environments to be defined only by their state.

---
## Future Improvements and Contributing
While I try to make this project fit into as many workflows as possible, I'd 
suggest forking this project and modifying it to fit your project workflow as 
necessary. If you have any suggestions or encounter any issues while running 
Terrafirm, feel free to file an issue or open a PR. 

In the future, I'd like to incorporate support for useful Terraform helper tools 
like [Terraform Landscape](https://github.com/coinbase/terraform-landscape) to 
provide a better experience for the end user. Ideally I will incorporate a 
Dockerfile into this project that builds an image containing the latest version 
of Terraform, Terrafirm itself, and any dependencies in order to offer an easier 
to get started with Terrafirm. Rewriting Terrafirm as a packageable executable is 
a potential for the future, but I prefer ~~to just write hacky functions~~ the 
simplicty of bash.