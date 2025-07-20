output "iot_data_bucket_name" {
  value = aws_s3_bucket.iot_data_bucket.bucket
}

output "iot_topic_rule_name" {
  value = aws_iot_topic_rule.iot_data_to_s3.name
}
