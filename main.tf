terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "daniel-secure-api-state"
    key            = "global/s3/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project   = "SecureAPIPlatform"
      ManagedBy = "Terraform"
      Env       = "Production"
    }
  }
}


output "cognito_user_pool_id" {
  value = module.cognito.user_pool_id
}

output "cognito_client_id" {
  value = module.cognito.client_id
}

output "api_endpoint" {
  value = module.api_gateway.api_url
}


# 1. Starta databasmodulen
module "database" {
  source = "./modules/database"
}

# 2. Uppdatera Lambda-modulen att ta emot databasinformation
module "lambda" {
  source            = "./modules/lambda"
  dynamodb_table_arn = module.database.table_arn
  dynamodb_table_name = module.database.table_name
}

module "cognito" {
  source = "./modules/cognito"
}

module "api_gateway" {
  source                = "./modules/api_gateway"
  cognito_user_pool_arn = module.cognito.user_pool_arn
  lambda_invoke_arn     = module.lambda.lambda_invoke_arn
}