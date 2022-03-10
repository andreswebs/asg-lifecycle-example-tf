terraform {
  required_version = "~> 1.1"

  required_providers {

    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.50"
    }

    external = {
      source = "hashicorp/external"
      version = "~> 2.2"
    }

  }
}