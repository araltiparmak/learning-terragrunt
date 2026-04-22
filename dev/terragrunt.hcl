include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

# locals {
# account_id  = "111111111111"
# aws_profile = "dev-profile"
# }

remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket = include.root.locals.bucket
    key    = "${path_relative_to_include()}/terraform.tfstate"
    region = include.root.locals.region
    # profile        = local.aws_profile
    encrypt        = true
    dynamodb_table = local.lock_table
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region              = "${include.root.locals.region}"
}
EOF
}

# profile             = "${local.aws_profile}"
# allowed_account_ids = ["${local.account_id}"]

inputs = merge(
  include.root.inputs,
  {
    name               = "dev-vpc"
    cidr               = "10.0.0.0/16"
    private_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
    enable_nat_gateway = false
    enable_vpn_gateway = false
    tags = merge(
      include.root.inputs.tags,
      {
        Environment = "dev"
      }
    )
  }
)
