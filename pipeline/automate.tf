# locals {
#   instances = csvdecode(file("srd22_accessKeys.csv"))
# }

variable "AWS_ACCESS_KEY_ID" {}

variable "AWS_SECRET_ACCESS_KEY" {}

provider "aws" {
  # access_key=tolist(local.instances)[0]["Access key ID"]
  # secret_key=tolist(local.instances)[0]["Secret access key"]
  access_key="${var.AWS_ACCESS_KEY_ID}"
  secret_key="${var.AWS_SECRET_ACCESS_KEY}"
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

data "aws_s3_bucket" "bucket" {
  bucket = "${var.s3_bucket}"
}

resource "aws_sqs_queue" "queue" {
  name = "s3-event-notification-queue"
  visibility_timeout_seconds = "330"
  policy = <<POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "sqs:SendMessage",
        "Resource": "arn:aws:sqs:*:*:s3-event-notification-queue",
        "Condition": {
          "ArnEquals": { "aws:SourceArn": "${data.aws_s3_bucket.bucket.arn}" }
        }
      }
    ]
  }
  POLICY
}

resource "aws_s3_bucket_notification" "bucket_notification_sqs" {
  bucket = data.aws_s3_bucket.bucket.id

  queue {
    queue_arn     = aws_sqs_queue.queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".json"
    
  }
}

resource "aws_lambda_function" "s2Quest" {
  s3_bucket        = "${var.s3_bucket}"
  s3_key           = "lambda_function.zip"
  function_name    = "LAST_PART"
  handler          = "s2Quest.lambda_handler"
  runtime          = "python3.9"
  timeout          = 300
  role             = "${aws_iam_role.s3_quest_terraform.arn}"
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  event_source_arn = "${aws_sqs_queue.queue.arn}"
  enabled          = true
  function_name    = "${aws_lambda_function.s2Quest.arn}"
  batch_size       = 1
}