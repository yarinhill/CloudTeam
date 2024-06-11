resource "aws_sqs_queue" "sqs" {
  name                       = var.sqs_queue_name
  delay_seconds              = 10
  max_message_size           = 262144
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 10

  tags = {
    Name  = var.sqs_queue_name
  }
}