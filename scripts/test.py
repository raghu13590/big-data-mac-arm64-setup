import json
import time
import requests
from collections import defaultdict
from kafka import KafkaProducer

# Constants
ELASTIC_URL = "http://vhlpfpbas009.tvlport.net:9204/pcc_qa/_search?size=10000"
ELASTIC_USER = "taa_pcc"
ELASTIC_PASS = "taa_pcc"
KAFKA_BROKERS = [
    "shlpfesdh101.tvlport.net:9092",
    "shlpfesdh110.tvlport.net:9092",
    "shlpfesdh111.tvlport.net:9092",
    "shlpfesdh112.tvlport.net:9092"
]
KAFKA_TOPIC = "test6"
FETCH_INTERVAL_SECS = 3600  # 1 hour; use 300 for 5 mins in testing

def fetch_from_elasticsearch():
    try:
        response = requests.get(ELASTIC_URL, auth=(ELASTIC_USER, ELASTIC_PASS))
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"[ERROR] Failed to fetch from Elasticsearch: {e}")
        return None

def extract_configs(data):
    configs = defaultdict(set)
    try:
        for hit in data["hits"]["hits"]:
            src = hit["_source"]
            kafka_topic = src.get("kafka", "").strip()
            pcc = src.get("pcc", "").strip()
            # Exclude any pcc that contains 'rule' (case-insensitive)
            if kafka_topic and pcc and "rule" not in pcc.lower():
                configs[pcc].add(kafka_topic)
        return {pcc: list(topics) for pcc, topics in configs.items()}
    except Exception as e:
        print(f"[ERROR] Failed to extract configs: {e}")
        return {}

def send_to_kafka(payload, producer):
    try:
        payload_str = json.dumps({"configs": payload})
        producer.send(KAFKA_TOPIC, value=payload_str.encode("utf-8"))
        producer.flush()
        print(f"[INFO] Sent to Kafka at {time.strftime('%Y-%m-%d %H:%M:%S')}")
        print(payload_str)  # For validation
    except Exception as e:
        print(f"[ERROR] Failed to send to Kafka: {e}")

def main_loop():
    producer = KafkaProducer(bootstrap_servers=KAFKA_BROKERS)
    while True:
        data = fetch_from_elasticsearch()
        if data:
            configs = extract_configs(data)
            if configs:
                send_to_kafka(configs, producer)
        time.sleep(FETCH_INTERVAL_SECS)

if __name__ == "__main__":
    main_loop()