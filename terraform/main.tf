resource "aws_s3_bucket" "iot_data_bucket" {
  bucket = "${var.project_name}-data-bucket"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.iot_data_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_iam_role" "iot_rule_role" {
  name = "${var.project_name}-iot-rule-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "iot.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "iot_to_s3_policy" {
  name = "${var.project_name}-iot-to-s3"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject"
        ],
        Resource = "${aws_s3_bucket.iot_data_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.iot_rule_role.name
  policy_arn = aws_iam_policy.iot_to_s3_policy.arn
}

resource "aws_iot_topic_rule" "iot_data_to_s3" {
  name = "${replace(var.project_name, "-", "_")}_iot_rule"
  enabled = true

  sql = <<EOF
SELECT * FROM 'iot/devices/data'
EOF

  sql_version = "2016-03-23"

  s3 {
    role_arn           = aws_iam_role.iot_rule_role.arn
    bucket_name        = aws_s3_bucket.iot_data_bucket.bucket
    key                = "data/${timestamp()}.json"
    canned_acl         = "private"
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name}_lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_s3_policy" {
  name = "${var.project_name}_lambda_s3"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          "${aws_s3_bucket.iot_data_bucket.arn}",
          "${aws_s3_bucket.iot_data_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = "logs:*",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

//resource "aws_lambda_function" "daily_report" {
  //function_name = "${var.project_name}_daily_report"
  //role          = aws_iam_role.lambda_exec_role.arn
  //handler       = "daily_report_generator.lambda_handler"
  //runtime       = "python3.11"
  //timeout       = 30
  //memory_size   = 256

  //filename         = "${path.module}/../lambda/daily_report_generator.zip"
  //source_code_hash = filebase64sha256("${path.module}/../lambda/daily_report_generator.zip")
//}

resource "aws_cloudwatch_event_rule" "daily_trigger" {
  name                = "${var.project_name}_daily_trigger"
  schedule_expression = "cron(0 0 * * ? *)"  # Daily at 00:00 UTC
}

resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule      = aws_cloudwatch_event_rule.daily_trigger.name
  target_id = "lambda"
  arn       = "arn:aws:lambda:ap-south-1:075212636906:function=${var.project_name}_daily_report"  # Hardcoded ARN if function exists already
}

resource "aws_lambda_permission" "allow_events" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${var.project_name}_daily_report"  # Just the name, not referencing a removed resource
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_trigger.arn
}
