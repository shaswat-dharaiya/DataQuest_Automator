locals {
  instances = csvdecode(file("../user/private_key.csv"))
}

variable "s3_bucket" {
  default = "s2quest"
}

provider "aws" {
  access_key=tolist(local.instances)[0]["Access key ID"]
  secret_key=tolist(local.instances)[0]["Secret access key"]
  region = "us-east-1"
}

data "aws_iam_role" "s3_quest_terraform" {
  name             = "automate_terraform"
}

resource "aws_lambda_function" "s3_script" {
  s3_bucket        = "${var.s3_bucket}"
  s3_key           = "lambda_function.zip"
  function_name    = "automate_quest"
  handler          = "s3_script.lambda_handler"
  runtime          = "python3.9"
  timeout          = 300
  role             = "${data.aws_iam_role.s3_quest_terraform.arn}"
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

resource "aws_lambda_function" "s2quest" {
  s3_bucket        = "${var.s3_bucket}"
  s3_key           = "lambda_function.zip"
  function_name    = "LAST_PART"
  handler          = "s2quest.lambda_handler"
  runtime          = "python3.9"
  timeout          = 300
  role             = "${data.aws_iam_role.s3_quest_terraform.arn}"
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  event_source_arn = "${aws_sqs_queue.queue.arn}"
  enabled          = true
  function_name    = "${aws_lambda_function.s2quest.arn}"
  batch_size       = 1
}