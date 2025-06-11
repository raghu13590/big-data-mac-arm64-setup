import logging
import os
import time
import re
import asyncio
import random
import multiprocessing
from datetime import datetime
import socket
import threading
import json
from aiokafka import AIOKafkaProducer
from aiokafka.errors import KafkaError
from typing import List

def setup_directory(path):
    """Create a directory if it does not exist."""
    if not os.path.exists(path):
        os.makedirs(path)

def configure_logging(log_dir):
    """Configure logging to write to a file in the specified directory."""
    log_file_name = os.path.join(log_dir, f'producer_log_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log')

    # Configure root logger
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file_name),
            logging.StreamHandler()
        ]
    )

    # Create a debug logger for process-specific throughput logs
    debug_logger = logging.getLogger('debug')
    debug_logger.setLevel(logging.DEBUG)

    # Add handlers to the debug logger
    debug_file = os.path.join(log_dir, f'debug_log_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log')
    debug_handler = logging.FileHandler(debug_file)
    debug_handler.setLevel(logging.DEBUG)
    debug_handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
    debug_logger.addHandler(debug_handler)

    return debug_logger

def replace_tags(message):
    """Replace tags in the message with appropriate values."""
    message = re.sub(r'<timestamp>', datetime.now().isoformat(), message)
    return message

def load_messages_from_file(file_path):
    """Read messages from a file and return them as a list."""
    with open(file_path, 'r') as file:
        file_content = file.read()
        messages = re.split(r'<message>(.*?)</message>', file_content, flags=re.DOTALL)
        return [message for message in messages if message.strip()]

async def create_producer():
    """Initialize and return an AIOKafka producer with optimized settings."""
    producer = AIOKafkaProducer(
        bootstrap_servers='shlpfesdh101.tvlport.net:9092,shlpfesdh102.tvlport.net:9092,shlpfesdh107.tvlport.net:9092,shlpfesdh108.tvlport.net:9092,shlpfesdh110.tvlport.net:9092,shlpfesdh111.tvlport.net:9092,shlpfesdh112.tvlport.net:9092,shlpfesdh115.tvlport.net:9092,shlpfesdh210.tvlport.net:9092,shlpfesdh211.tvlport.net:9092',
        client_id=socket.gethostname(),
        max_batch_size=200000,
        linger_ms=5,                   # Reduced to minimize latency while maintaining batching
        compression_type='gzip',       # Using gzip compression
        acks=1,                        # Using 1 to improve throughput
        max_request_size=10485760,     # 10MB max request size
        request_timeout_ms=60000,      # 60 seconds timeout
    )
    await producer.start()
    return producer

async def send_message_batch(producer, topic, messages, batch_size=1000):
    """Send messages in optimized batches."""
    sending_tasks = []

    # Create sending tasks for each message in the batch
    for msg in messages:
        encoded_msg = msg.encode('utf-8')
        sending_tasks.append(producer.send(topic, encoded_msg))

        # Process in sub-batches to avoid memory issues
        if len(sending_tasks) >= batch_size:
            await asyncio.gather(*sending_tasks)
            sending_tasks = []

    # Process any remaining messages
    if sending_tasks:
        await asyncio.gather(*sending_tasks)

    return len(messages)

async def producer_task(topic, messages, process_id, stats_interval=5.0, stats_file=None, debug_logger=None):
    """Producer task to be run in a separate process."""
    logging.info(f"Process {process_id}: Starting producer")

    # Pre-process all messages before starting
    processed_messages = [replace_tags(msg.strip()) for msg in messages if msg.strip()]

    if not processed_messages:
        logging.warning(f"Process {process_id}: No messages to send")
        return

    # Create the producer
    producer = await create_producer()

    start_time = time.time()
    message_count = 0
    last_report_time = start_time
    total_sent = 0

    try:
        # Split messages into larger batches for processing
        batch_size = 1000  # Process 1000 messages at a time
        message_batches = [processed_messages[i:i + batch_size]
                          for i in range(0, len(processed_messages), batch_size)]

        # Process batches in a loop for continuous sending
        while True:
            for batch in message_batches:
                # Send the batch and count sent messages
                sent_count = await send_message_batch(producer, topic, batch)
                message_count += sent_count
                total_sent += sent_count

                # Report statistics periodically
                current_time = time.time()
                if current_time - last_report_time >= stats_interval:
                    elapsed = current_time - last_report_time
                    rate = message_count / elapsed

                    # Log detailed stats at DEBUG level
                    if debug_logger:
                        debug_logger.debug(f"Process {process_id}: Sent {message_count} messages in {elapsed:.2f} seconds ({rate:.2f} messages/sec)")
                    else:
                        logging.debug(f"Process {process_id}: Sent {message_count} messages in {elapsed:.2f} seconds ({rate:.2f} messages/sec)")

                    # Write to stats file for aggregation
                    if stats_file:
                        try:
                            with open(stats_file, 'a') as f:
                                timestamp = int(current_time)
                                f.write(f"{timestamp},{process_id},{message_count},{elapsed},{rate}\n")
                        except Exception as e:
                            logging.error(f"Error writing to stats file: {e}")

                    message_count = 0
                    last_report_time = current_time

    except KeyboardInterrupt:
        logging.info(f"Process {process_id}: Stopping producer...")
    except Exception as e:
        logging.error(f"Process {process_id}: Error in producer task: {e}")
    finally:
        # Make sure to flush and close the producer
        await producer.stop()
        end_time = time.time()
        total_elapsed = end_time - start_time
        avg_rate = total_sent / total_elapsed if total_elapsed > 0 else 0
        logging.info(f"Process {process_id}: Producer stopped. Total sent: {total_sent} messages in {total_elapsed:.2f} seconds ({avg_rate:.2f} messages/sec)")

def run_async_process(topic, messages, process_id, stats_file, debug_logger):
    """Function to run the asyncio event loop in a separate process."""
    try:
        # Python 3.6 compatible approach for running the event loop
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        try:
            loop.run_until_complete(producer_task(topic, messages, process_id, stats_file=stats_file, debug_logger=debug_logger))
        finally:
            loop.close()
    except Exception as e:
        logging.error(f"Process {process_id}: Fatal error: {e}")

def log_aggregated_stats(stats_file, interval=60):
    """Periodically read the stats file and log aggregated throughput."""
    last_log_time = datetime.now().replace(second=0, microsecond=0)

    while True:
        current_time = datetime.now()

        # Check if it's time to log (every minute)
        if (current_time - last_log_time).total_seconds() >= interval:
            try:
                # Read stats from file
                if os.path.exists(stats_file):
                    with open(stats_file, 'r') as f:
                        lines = f.readlines()

                    # Filter to get recent stats only (last minute)
                    current_timestamp = int(time.time())
                    recent_stats = []

                    for line in lines:
                        parts = line.strip().split(',')
                        if len(parts) >= 5:
                            timestamp, process_id, count, elapsed, rate = parts
                            if current_timestamp - int(timestamp) < interval + 10:  # Add a small buffer
                                recent_stats.append(float(rate))

                    # Calculate and log aggregate statistics
                    if recent_stats:
                        avg_rate = sum(recent_stats) / len(recent_stats)
                        total_rate = sum(recent_stats)
                        logging.info(f"AGGREGATE THROUGHPUT: {total_rate:.2f} messages/sec total across {len(recent_stats)} processes (avg: {avg_rate:.2f} msg/sec per process)")

                    # Truncate the file to prevent it from growing too large
                    with open(stats_file, 'w') as f:
                        pass

            except Exception as e:
                logging.error(f"Error aggregating stats: {e}")

            last_log_time = current_time.replace(second=0, microsecond=0)

        # Sleep to avoid busy waiting
        time.sleep(1)

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    log_dir = os.path.join(script_dir, 'logs')
    data_dir = os.path.join(script_dir, 'messages')

    setup_directory(log_dir)
    setup_directory(data_dir)

    # Configure loggers
    debug_logger = configure_logging(log_dir)

    # Create a stats file for inter-process communication
    stats_file = os.path.join(log_dir, f'throughput_stats_{datetime.now().strftime("%Y%m%d_%H%M%S")}.csv')
    with open(stats_file, 'w') as f:
        f.write("timestamp,process_id,message_count,elapsed,rate\n")

    TOPICS = ['env_v2_in']
    for topic in TOPICS:
        setup_directory(os.path.join(data_dir, topic))

    # Load messages for each topic
    messages_by_topic = {}
    for topic in TOPICS:
        folder_path = os.path.join(data_dir, topic)
        txt_files = [f for f in os.listdir(folder_path) if f.endswith('.txt')]
        messages_by_topic[topic] = []
        for filename in txt_files:
            file_path = os.path.join(folder_path, filename)
            messages_by_topic[topic].extend(load_messages_from_file(file_path))
        logging.info(f"Loaded {len(messages_by_topic[topic])} messages for topic {topic}")

        # If you have very few messages, duplicate them to test throughput
        if len(messages_by_topic[topic]) < 100:
            original_messages = messages_by_topic[topic].copy()
            for _ in range(1000):  # Duplicate 1000x to have enough messages for testing
                messages_by_topic[topic].extend(original_messages)
            logging.info(f"Duplicated messages to {len(messages_by_topic[topic])} for testing throughput")

    # Start a thread to periodically log aggregated statistics
    stats_thread = threading.Thread(
        target=log_aggregated_stats,
        args=(stats_file, 60),  # Log every 60 seconds
        daemon=True
    )
    stats_thread.start()

    # Start multiple producer processes
    processes = []
    num_processes = min(8, multiprocessing.cpu_count())  # Use up to 8 processes or CPU count

    try:
        for topic, messages in messages_by_topic.items():
            # Split messages roughly evenly among processes
            messages_per_process = max(1, len(messages) // num_processes)

            for i in range(num_processes):
                # Calculate the slice of messages for this process
                start_idx = i * messages_per_process
                end_idx = None if i == num_processes - 1 else (i + 1) * messages_per_process
                process_messages = messages[start_idx:end_idx]

                if not process_messages:
                    continue

                # Start a new process
                p = multiprocessing.Process(
                    target=run_async_process,
                    args=(topic, process_messages, i, stats_file, debug_logger)
                )
                p.start()
                processes.append(p)
                logging.info(f"Started producer process {i} for topic {topic}")

        # Wait for processes to complete
        for p in processes:
            p.join()

    except KeyboardInterrupt:
        logging.info("Main process interrupted, stopping all producers...")
        for p in processes:
            if p.is_alive():
                p.terminate()
                p.join(timeout=5)
        logging.info("All producers stopped")
