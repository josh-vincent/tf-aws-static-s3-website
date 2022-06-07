locals {
  region = "ap-southeast-2"
  application = "LinkedInOffers"
}

data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name = "staticS3ApiGateway"
}

resource "aws_api_gateway_resource" "resource" {
  path_part   = "resource"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# OPTIONS HTTP method.
resource "aws_api_gateway_method" "options" {
  rest_api_id      = aws_api_gateway_rest_api.api.id
  resource_id      = aws_api_gateway_resource.resource.id
  http_method      = "OPTIONS"
  authorization    = "NONE"
  api_key_required = false
}

# OPTIONS method response.
resource "aws_api_gateway_method_response" "options" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# OPTIONS integration.
resource "aws_api_gateway_integration" "options" {
  rest_api_id          = aws_api_gateway_rest_api.api.id
  resource_id          = aws_api_gateway_resource.resource.id
  http_method          = "OPTIONS"
  type                 = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"
  request_templates = {
    "application/json" : "{\"statusCode\": 200}"
  }
}

# OPTIONS integration response.
resource "aws_api_gateway_integration_response" "options" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_integration.options.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.sample_lambda.invoke_arn
}

#Stages
resource "aws_api_gateway_stage" "test" {
  stage_name    = "test"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.test.id
}

resource "aws_api_gateway_deployment" "test" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "test"
  depends_on  = [aws_api_gateway_integration.integration]
}

# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sample_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${local.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
}

# Policies
resource "aws_iam_policy" "lambda_logging" {
  name        = "${local.application}_lambda_logging"
  path        = "/"
  description = "IAM policy for ${local.application} logging from a lambda"
  policy      = file("${path.root}/files/policy/lambda_logging_policy.json")
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_role_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_policy" "dynamodb_policy" {
  name        = "${local.application}_dynamodb_policy"
  path        = "/"
  description = "DynamoDB policy for a ${local.application} lambda"
  policy      = templatefile("${path.root}/files/policy/dynamodb_policy.json",
  {
    table_name = var.table_name
    account = data.aws_caller_identity.current.account_id
    region = local.region
  })
}
resource "aws_iam_role_policy_attachment" "dynamodb_role_attachment" {
  role       = aws_iam_role.iam_role_for_lambda.name
  policy_arn = aws_iam_policy.dynamodb_policy.arn
}


# IAM
resource "aws_iam_role" "iam_role_for_lambda" {
  name               = "${local.application}_iam_role_for_lambda"
  assume_role_policy = file("${path.root}/files/policy/lambda_assume_role_policy.json")
}
locals {
  function_name = "hello-world-lambda"
  handler       = "helloworld.handler"
  // The .zip file we will create and upload to AWS later on
  zip_file = "hello-world-lambda.zip"
}

data "archive_file" "lambda_zip" {
  excludes = [
    ".env",
    ".terraform",
    ".terraform.lock.hcl",
    "docker-compose.yml",
    "main.tf",
    "terraform.tfstate",
    "terraform.tfstate.backup",
    local.zip_file,
  ]
  source_dir = "${path.root}/files/functions/"
  type       = "zip"
  // Create the .zip file in the same directory as the helloworld.js file
  output_path = "${path.root}/functions/${local.zip_file}"
}


resource "aws_lambda_function" "sample_lambda" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "${local.application}_hello_world_function"
  role          = aws_iam_role.iam_role_for_lambda.arn
  handler       = "helloworld.handler"
  // Upload the .zip file Terraform created to AWS
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "nodejs12.x"

  environment {
    variables = {
      test = "test"
    }
  }
}