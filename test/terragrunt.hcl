include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

# locals {
#   account_id  = "111111111111"
#   aws_profile = "test-profile"
# }

remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket         = include.root.locals.bucket
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = include.root.locals.region
    encrypt        = true
    dynamodb_table = local.lock_table
    # profile        = local.aws_profile
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
    name               = "test-vpc"
    cidr               = "10.1.0.0/16"
    private_subnets    = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
    public_subnets     = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
    enable_nat_gateway = false
    enable_vpn_gateway = false
    tags = merge(
      include.root.inputs.tags,
      {
        Environment = "test"
      }
    )
  }
)
