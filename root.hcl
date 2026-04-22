terragrunt_version_constraint = ">= 1.0.2"
terraform_version_constraint  = ">= 1.5"

locals {
  region     = "eu-central-1"
  bucket     = "terragrunt-learning-bucket"
  lock_table = "terraform-locks"
}

terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=6.6.1"
}

inputs = {
  azs = [for suffix in ["a", "b", "c"] : "${local.region}${suffix}"]
  tags = {
    ManagedBy = "Terragrunt"
  }
}
