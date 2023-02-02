locals {
  instances = csvdecode(file("srd22_accessKeys.csv"))
}

provider "aws" {
access_key=tolist(local.instances)[0]["Access key ID"]
secret_key=tolist(local.instances)[0]["Secret access key"]
region = "us-east-1"
}


data "aws_iam_policy_document" "AWSLambdaTrustPolicy" {
  statement {
    actions    = ["sts:AssumeRole"]
    effect     = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "s3_quest_terraform" {
  name               = "automate_terraform"
  assume_role_policy = "${data.aws_iam_policy_document.AWSLambdaTrustPolicy.json}"
}

resource "aws_iam_role_policy_attachment" "srd_policy-attachment" {
  for_each = toset([
    "arn:aws:iam::aws:policy/IAMFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess", 
    "arn:aws:iam::aws:policy/AmazonS3FullAccess", 
    "arn:aws:iam::aws:policy/AWSLambda_FullAccess",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess",
    "arn:aws:iam::aws:policy/AmazonEventBridgeFullAccess",
    "arn:aws:iam::aws:policy/AmazonEventBridgeSchemasFullAccess",
    "arn:aws:iam::aws:policy/AmazonEventBridgeSchedulerFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ])
  role       = "${aws_iam_role.s3_quest_terraform.name}"
  policy_arn = each.value
}

resource "aws_lambda_function" "s3_script" {
  s3_bucket        = "${var.s3_bucket}"
  s3_key           = "lambda_function.zip"
  function_name    = "automate_quest"
  handler          = "s3_script.lambda_handler"
  runtime          = "python3.9"
  timeout          = 300
  role             = "${aws_iam_role.s3_quest_terraform.arn}"
}

resource "aws_cloudwatch_event_rule" "every_day" {
    name = "every_day"
    description = "Fires every 1 day"
    schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "script_every_day" {
    rule = aws_cloudwatch_event_rule.every_day.name
    target_id = "s3_script"
    arn = aws_lambda_function.s3_script.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_s3_script" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.s3_script.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.every_day.arn
}


