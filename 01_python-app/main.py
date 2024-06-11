import boto3
import datetime
import os
import logging
import time

sqs = boto3.client('sqs', region_name=os.environ['AWS_REGION'])
s3 = boto3.client('s3', region_name=os.environ['AWS_REGION'])

QUEUE_URL = os.environ['QUEUE_URL']
BUCKET_NAME = os.environ['BUCKET_NAME']

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def receive_message():
    logging.info('Listening for messages from SQS')
    try:
        response = sqs.receive_message(
            QueueUrl=QUEUE_URL,
            MaxNumberOfMessages=1,
            WaitTimeSeconds=10
        )
        messages = response.get('Messages', [])
        if messages:
            logging.info(f'Received {len(messages)} message(s)')
            for message in messages:
                logging.info(f"Message body: {message['Body']}")
        else:
            logging.info('No messages received')
        return messages
    except Exception as e:
        logging.error(f"Error receiving message: {e}")
        return []

def save_to_s3(message_body):
    try:
        timestamp = datetime.datetime.now().strftime('%Y-%m-%d-%H-%M-%S')
        filename = f'{timestamp}.txt'
        logging.info(f'Saving message to S3 with filename: {filename}')
        s3.put_object(Bucket=BUCKET_NAME, Key=filename, Body=message_body)
        logging.info('Message saved to S3')
    except Exception as e:
        logging.error(f"Error saving message to S3: {e}")

def delete_message(receipt_handle):
    try:
        logging.info('Deleting message from SQS')
        sqs.delete_message(
            QueueUrl=QUEUE_URL,
            ReceiptHandle=receipt_handle
        )
        logging.info('Message deleted from SQS')
    except Exception as e:
        logging.error(f"Error deleting message from SQS: {e}")

def main():
    while True:
        messages = receive_message()
        if messages:
            for message in messages:
                save_to_s3(message['Body'])
                delete_message(message['ReceiptHandle'])
        else:
            logging.info('No messages to process')
            break
        time.sleep(10)  

if __name__ == '__main__':
    main()
