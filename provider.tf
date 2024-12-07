terraform {
  required_version = "= 1.9.8"

  required_providers {
    aws = {
      version = "= 5.78.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      owner = "morimoto"
    }
  }
}
