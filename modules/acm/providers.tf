provider "aws" {
  alias = "acm_provider"
  region = "us-east-1"
  # This is because certificates have to be added in us-east-1 for cloudfront
}