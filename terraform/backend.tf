terraform {
  required_version = "~> 1.0"
  backend "s3" {
    encrypt = true
    key     = "terraform.tfstate"
    region  = "eu-west-2"
    # bucket is omitted here because it is specified as part of the backend config for the environment
    # terraform init -backend-config=environments/$ENVIRONMENT/backend.hcl
  }
}
