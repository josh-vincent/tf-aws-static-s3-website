module s3 {
  source = "./modules/s3"
  domain_name = var.domain_name
}

module apiGateway {
  source = "./modules/apiGateway"
  table_name = module.dynamodb.dynamodb_table_name
  depends_on = [module.dynamodb]
}

module dynamodb {
  source = "./modules/dynamodb"
}
#module acm {
#  source = "./modules/acm"
#  domain_name = var.domain_name
#}

module cloudfront {
  source = "./modules/cloudfront"
  domain_name = var.domain_name
  bucket_details = module.s3.bucket_details
  acm_cert = ""#module.acm.acm_cert
}