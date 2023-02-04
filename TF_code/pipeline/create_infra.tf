# Acccess the user's credentials
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

# Access the IAM Role created earlier
data "aws_iam_role" "s3_quest_terraform" {
  name             = "automate_terraform"
}

# -----------------------STEP 4.1-----------------------

# Create the lambda function that executes Step 1 and 2.
resource "aws_lambda_function" "s3_script" {
  s3_bucket        = "${var.s3_bucket}"
  s3_key           = "lambda_files.zip"
  function_name    = "automate_quest"
  handler          = "s3_script.lambda_handler"
  runtime          = "python3.9"
  timeout          = 300
  role             = "${data.aws_iam_role.s3_quest_terraform.arn}"
  # Attach the pandas sdk layer to the function.
  layers           = ["arn:aws:lambda:us-east-1:336392948345:layer:AWSSDKPandas-Python39:3"]
}

# Create a Cloudwatch rule that triggers once everyday.
resource "aws_cloudwatch_event_rule" "every_day" {
    name = "every_day"
    description = "Fires every 1 day"
    schedule_expression = "rate(1 day)"
}

# Attach this rule to the lambda function.
resource "aws_cloudwatch_event_target" "script_every_day" {
    rule = aws_cloudwatch_event_rule.every_day.name
    target_id = "s3_script"
    arn = aws_lambda_function.s3_script.arn
}

# Give Cloudwatch proper permission to execute the script.
resource "aws_lambda_permission" "allow_cloudwatch_to_call_s3_script" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.s3_script.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.every_day.arn
}

# -----------------------STEP 4.2-----------------------

# Access the pre-existing S3 bucket: s2quest.
data "aws_s3_bucket" "bucket" {
  bucket = "${var.s3_bucket}"
}

# Create an SQS Queue that will get attached to the S3 bucket: s2quest.
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

# Attach a notification service to S3 such that
# when a file with ".json" gets uploaded/updated to S3,
# It triggers an entry to the SQS Queue
resource "aws_s3_bucket_notification" "bucket_notification_sqs" {
  bucket = data.aws_s3_bucket.bucket.id
  queue {
    queue_arn     = aws_sqs_queue.queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".json"
    
  }
}

# -----------------------STEP 4.3-----------------------

# Upon an entry to the above created queue,
# It triggers a lambda executes the Step 3.
resource "aws_lambda_function" "s2quest" {
  s3_bucket        = "${var.s3_bucket}"
  s3_key           = "lambda_files.zip"
  function_name    = "S4-3"
  handler          = "s2quest.lambda_handler"
  runtime          = "python3.9"
  timeout          = 300
  role             = "${data.aws_iam_role.s3_quest_terraform.arn}"
  layers           = ["arn:aws:lambda:us-east-1:336392948345:layer:AWSSDKPandas-Python39:3"]


}

# An event source mapping basically registers an entry to sqs queue as an event,
# and maps it corresponding response, ie. executing the lambda function: S4-3
resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  event_source_arn = "${aws_sqs_queue.queue.arn}"
  enabled          = true
  function_name    = "${aws_lambda_function.s2quest.arn}"
  batch_size       = 1
}