# S3 bucket for website.
resource "aws_s3_bucket" "www_bucket" {
  bucket = var.domain_name
  tags = yamldecode(templatefile("${path.root}/files/tags/tags.yaml", {}))
}

#Send output of bucket for other modules to use
output bucket_details {
  value = aws_s3_bucket.www_bucket
}

#Bucket Policy
resource "aws_s3_bucket_policy" "static_policy" {
  bucket = aws_s3_bucket.www_bucket.id
  policy = templatefile("${path.root}/files/s3/s3-policy.json", { bucket = var.domain_name })
}

#Bucket ACL
resource "aws_s3_bucket_acl" "example_bucket_acl" {
  bucket = aws_s3_bucket.www_bucket.id
  acl    = "public-read"
}

#CORS Rules
resource "aws_s3_bucket_cors_configuration" "example" {
  bucket = aws_s3_bucket.www_bucket.bucket

  cors_rule {
    allowed_headers = ["Authorization", "Content-Length"]
    allowed_methods = ["GET", "POST"]
    allowed_origins = ["https://${var.domain_name}"]
    max_age_seconds = 3000
    expose_headers  = ["ETag"]
  }

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

resource "aws_s3_bucket_website_configuration" "www_bucket_config" {
  bucket = var.domain_name

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_website_configuration" "root_bucket_config" {
  bucket = var.domain_name

  redirect_all_requests_to {
    host_name = var.domain_name
    protocol = "https"
  }
}

resource "aws_s3_object" "object" {
  for_each = fileset("${path.root}/files/website", "**/*")
  bucket = aws_s3_bucket.www_bucket.bucket
  key    = each.key
  source = "${path.root}/files/website/${each.key}"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("${path.root}/files/website/${each.key}")
}