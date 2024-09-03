import logging
import os
import time
import re
from kafka import KafkaProducer
import random
from datetime import datetime, timedelta

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Get data directory from environment variable, default to /app/data if not set
DATA_DIR = os.getenv('DATA_DIR', '/app/data')
MESSAGES_DIR = os.path.join(DATA_DIR, 'messages')

# Ensure the messages directory exists
os.makedirs(MESSAGES_DIR, exist_ok=True)

# Kafka producer setup
producer = KafkaProducer(
    bootstrap_servers='kafka:9092',
    value_serializer=lambda v: v.encode('utf-8')
)

topic = 'your-topic-name'

# Variables for message counting
message_count = 0
last_log_time = datetime.now().replace(second=0, microsecond=0)

def process_and_send_messages(file_content):
    global message_count
    # Split the content into separate messages
    messages = re.split(r'<message>(.*?)</message>', file_content, flags=re.DOTALL)

    for message in messages:
        if message.strip():
            # Process tags within the message
            processed_message = replaceTags(message.strip())
            producer.send(topic, value=processed_message)
            message_count += 1
            logging.debug(f'Sent message: {processed_message[:50]}...')  # Log first 50 chars

# replaces tags in the message with the appropriate values
def replaceTags(message):
    # Replace <timestamp> with current timestamp
    message = re.sub(r'<timestamp>', datetime.now().isoformat(), message)

    # Replace <id> with a random number between 1 and 10000
    message = re.sub(r'<id>', lambda _: str(random.randint(1, 10000)), message)

    return message

# Read messages from a file and send them to Kafka
def send_messages_from_file(file_path):
    with open(file_path, 'r') as file:
        file_content = file.read()
        process_and_send_messages(file_content)

def log_message_count():
    global message_count, last_log_time
    current_time = datetime.now()
    if current_time.second == 0 and (current_time - last_log_time).total_seconds() >= 60:
        logging.info(f"Messages sent in the last minute: {message_count}")
        message_count = 0
        last_log_time = current_time

try:
    while True:
        # Get list of .txt files in the messages directory
        txt_files = [f for f in os.listdir(MESSAGES_DIR) if f.endswith('.txt')]

        if txt_files:
            for filename in txt_files:
                file_path = os.path.join(MESSAGES_DIR, filename)
                send_messages_from_file(file_path)
        else:
            logging.debug("No .txt files found in the messages directory. Waiting...")

        # Log message count every minute
        log_message_count()

        # Wait before checking for files again
        time.sleep(1)
except KeyboardInterrupt:
    logging.info("Stopping producer...")
finally:
    producer.close()