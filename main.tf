provider "aws" {
  region = "eu-west-3"
  access_key = "ACCESS_KEY"
  secret_key = "SECRET_KEY"
}

resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = "job-api"
  description = "API pour la gestion des jobs"
}

resource "aws_api_gateway_resource" "jobs_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "jobs"
}

resource "aws_api_gateway_method" "add_job_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.jobs_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "add_job_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.jobs_resource.id
  http_method             = aws_api_gateway_method.add_job_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.add_job_lambda.invoke_arn
}

resource "aws_lambda_function" "add_job_lambda" {
  function_name = "addJobLambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "add_job.handler"
  runtime       = "nodejs14.x"
  filename      =  "./main.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role" "lambda_policy" {
    name = "lambda_policy"
    assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
POLICY
}

resource "aws_dynamodb_table" "jobs_table" {
  name         = "jobs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_api_gateway_deployment" "api_gateway_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "prod"
}


output "api_gateway_url" {
  value = aws_api_gateway_deployment.api_gateway_deployment.invoke_url
}




