FROM python:3.9-slim

RUN apt-get update && apt-get install -y procps && rm -rf /var/lib/apt/lists/*
RUN pip install kafka-python watchdog

WORKDIR /app
COPY kafkaproducer.py /app/
RUN pip install kafka-python

CMD ["python", "kafkaproducer.py"]