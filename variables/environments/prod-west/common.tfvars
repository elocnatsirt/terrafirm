# We source aws_provider.tf in our AWS configs and set the default to us-east-1.
# This allows us to override the region and profile we use to deploy 
# infrastructure in a different region while changing nothing but variables.
#
# Note that this change would not affect where your state files are stored.
#
aws = {
  region           = "us-west-1"
  aws_profile_name = "default-west"
}

common = {
  example_variable = "prod_west_example"
}