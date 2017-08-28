variable "bucket" {}
variable "rollbar_access_token" {}

provider "aws" {
  region = "ap-northeast-1"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.bucket}"
  acl    = "private"
}

resource "aws_iam_role" "lambda_s3_readonly_role" {
  name = "lambda_s3_readonly_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_s3_readonly_policy" {
  name = "lambda_s3_readonly_policy"
  role = "${aws_iam_role.lambda_s3_readonly_role.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:logs:ap-northeast-1:${data.aws_caller_identity.current.account_id}:*"
      ]
    },
    {
      "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:logs:ap-northeast-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/rollbar_test:*"
      ]
    },
    {
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${var.bucket}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_lambda_permission" "allow_s3_to_invoke_rollbar_test" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.rollbar_test.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.bucket.arn}"
}

resource "aws_lambda_function" "rollbar_test" {
  function_name    = "rollbar_test"
  filename         = "rollbar_test.zip"
  source_code_hash = "${base64sha256(file("rollbar_test.zip"))}"
  role             = "${aws_iam_role.lambda_s3_readonly_role.arn}"
  handler          = "index.handler"
  runtime          = "nodejs6.10"

  environment {
    variables = {
      ROLLBAR_ACCESS_TOKEN = "${var.rollbar_access_token}"
    }
  }
}

resource "aws_s3_bucket_notification" "s3_lambda_notification" {
  bucket = "${aws_s3_bucket.bucket.id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.rollbar_test.arn}"
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".json"
  }
}
