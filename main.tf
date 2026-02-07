resource "aws_glue_catalog_database" "data_db" {
  name = "MyCatalogDatabase"
}

resource "aws_glue_crawler" "data_crawler" {
  database_name = aws_glue_catalog_database.data_db.name
  name          = "pipeline-data-crawler"
  role          = aws_iam_role.lambda_role.arn # IAM role for permissions

  s3_target {
    path = "s3://${aws_s3_bucket.processed_data.bucket}/"
  }
}

# Processor Lambda: Triggers on S3 Upload
resource "aws_lambda_function" "processor" {
  filename      = "processor.zip" # Jenkins will build this
  function_name = "DataProcessor"
  role          = aws_iam_role.lambda_role.arn
  handler       = "processor.handler"
  runtime       = "python3.9"
  source_code_hash = filebase64sha256("processor.zip")
}


# Reporter Lambda: Triggers on Schedule
resource "aws_lambda_function" "reporter" {
  filename      = "reporter.zip"
  function_name = "DailyReporter"
  role          = aws_iam_role.lambda_role.arn
  handler       = "reporter.handler"
  runtime       = "python3.9"
  source_code_hash = filebase64sha256("reporter.zip")
}


# S3 Notification to Trigger Processor
resource "aws_s3_bucket_notification" "raw_upload_trigger" {
  bucket = aws_s3_bucket.raw_data.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.processor.arn
    events              = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_lambda_permission.allow_s3_to_call_processor]
}

#eventbridge rule

resource "aws_cloudwatch_event_rule" "daily_timer" {
  name                = "daily-reporting-schedule"
  schedule_expression = "cron(0 9 * * ? *)" # Every day at 9 AM UTC
}

resource "aws_cloudwatch_event_target" "trigger_reporter_lambda" {
  rule      = aws_cloudwatch_event_rule.daily_timer.name
  target_id = "SendDailyReport"
  arn       = aws_lambda_function.reporter.arn
}


# 6. Lambda Permissions (Allowing Triggers)
resource "aws_lambda_permission" "allow_s3_to_call_processor" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.raw_data.arn
}


resource "aws_lambda_permission" "allow_eventbridge_to_call_reporter" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.reporter.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_timer.arn
}
