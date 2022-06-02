module s3 {
  source = "./modules/s3"
  domain_name = var.domain_name
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