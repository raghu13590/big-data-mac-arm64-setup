# Big Data Mac ARM64 Setup

This project sets up a big data environment on a Mac with ARM64 architecture using Docker. It includes scripts to manage and run Zookeeper, Kafka, AKHQ (a GUI for Kafka), Pinot, Superset, ZooNavigator, Spark, and Flink services.

## Overview

This project provides a streamlined way to set up and manage a big data environment. It includes Docker Compose files for setting up Zookeeper, Kafka, Pinot, Superset, ZooNavigator, Spark, and Flink, along with shell scripts to manage these services, ensuring they run correctly and efficiently.

### Features

- **Docker Compose Integration**: Easily manage services using Docker Compose.
- **Health Checks**: Automatically verify that services are healthy.
- **Orphan Container Cleanup**: Remove orphan containers before starting new ones.
- **Network Management**: Ensure services are on the same Docker network.
- **Ease of Use**: Scripts can be run from any directory.

## Prerequisites

- Docker or Docker Desktop
- Bash

## Setup Instructions

### 1. Clone the Repository
```sh
git clone https://github.com/your-repo/big-data-mac-arm64-setup.git
cd big-data-mac-arm64-setup
```

###  2. Make Scripts Executable
Ensure the scripts have executable permissions:
```sh
chmod +x docker/scripts/*.sh
```

### 3. Running the Services

### 3.1. To start Zookeeper, run:
```sh
./docker/scripts/run-zookeeper.sh
```
This script will start the Zookeeper service with two instances and ensures they are running and healthy.
Once Zookeeper is running, you can access the Zookeeper Admin UI for managing and monitoring at  http://localhost:8081/commands, http://localhost:8082/commands and http://localhost:8083/commands. 
Use the available links to navigate to different commands like monitor, stat, conf, etc.

### 3.2. To start Kafka, run:
```sh
./docker/scripts/run-kafka.sh
```
This script will start the Kafka service and ensure it is running and healthy.

### 3.3. To start AKHQ (Kafka UI), run:
```sh
./docker/scripts/run-akhq.sh
```
This script will start the AKHQ service and ensure it is running and healthy. AKHQ is a UI for managing and monitoring Apache Kafka clusters. It provides a user-friendly interface to manage topics, consumer groups, and other Kafka resources.
Once the service is up and running, you can access AKHQ at http://localhost:9093.

### 3.4. To start Pinot, run:
```sh
./docker/scripts/run-pinot.sh
```
This script will start the Pinot controller, broker, and server services, ensuring they are running and healthy.
Once the services are up and running, you can access Apache Pinot at http://localhost:9000.

### 3.5. To start Superset, run:
```sh
./docker/scripts/run-superset.sh
```
This script will start the Superset service, generate a random secret key, and ensure the service is running and healthy.
Once the services are up and running, you can access Apache Superset at http://localhost:8088.

### 3.6. To start ZooNavigator, run:
```sh
./docker/scripts/run-zoonavigator.sh
```
This script will start the ZooNavigator service and ensure it is running and healthy.
Open ZooNavigator in your browser at http://localhost:9001.
    •	Enter Zookeeper connection string as zookeeper1:2181 and click connect, you will be connected to zookeeper1 cluster.
    •	You can now view the Zookeeper1 tree and manage nodes. 
    •	click disconnect on top-right to disconnect from the zookeeper1 cluster.
    •	Enter Zookeeper connection string as zookeeper2:2181 and click connect, you will be connected to zookeeper2 cluster.
    •	You can now view the Zookeeper2 tree and manage nodes.

### 3.7. To start Spark, run:
```sh
./docker/scripts/run-spark.sh
```
This script will start the Spark master and worker services and ensure they are running and healthy.
Once the services are up and running, you can access the Spark Master UI at http://localhost:8072 and the Spark Worker UI at http://localhost:8073.
Place your Spark job JAR files in the `docker/app-data/spark/local-jars` folder. Optionally you can place data files in the `docker/app-data/spark/datasets` folder and modify the Spark job accordingly to read the data files from the datasets folder.
To run a Spark job, use the following command:
```sh
docker exec -it spark-master

spark-submit \
    --master spark://spark-master:7077 \
    --class com.abc.MainClass \
    --executor-memory 1G \
    --total-executor-cores 1 \
    /opt/spark/local-jars/yourjar.jar
```

to debug the spark job with remote debugging, you can use the following command:
```sh
docker exec -it spark-master

spark-submit \
  --master spark://spark-master:7077 \
  --class com.abc.MainClass \
  --executor-memory 1G \
  --total-executor-cores 1 \
  --conf "spark.driver.extraJavaOptions=-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005" \
  --conf "spark.executor.extraJavaOptions=-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005" \
   /opt/spark/local-jars/yourjar.jar
```
to step through the code in the spark job,**set suspend=y** in the above command and then attach the debugger in your IDE to the port 5005.
for example, In IntelliJ IDEA, you can create a new Remote configuration and attach it to the port 5005.
go to Run -> Edit Configurations -> Add New Configuration -> Remote -> set the port to 5005 and hostname to localhost and click on the debug button.

### 3.8. To start Flink, run:
```sh
./docker/scripts/run-flink.sh
```
This script will start the Flink job manager and task manager services and ensure they are running and healthy.
To run Flink with flame graphs uncomment rest.flamegraph.enabled: true in the flink-conf.yaml file in the docker/service-data/flink/conf folder.
Once the services are up and running, you can access the Flink Job Manager UI at http://localhost:8074.

### 3.9. To start the Kafka Producer, run:
```sh
./docker/scripts/run-kafkaproducer.sh
```
This script will start the Kafka Producer service, which continuously sends messages to a specified Kafka topic.
Add .txt files with messages you'd like to send to the topic in the `docker/service-data/kafkaproducer/messages` folder. You can also modify each message by replacing the text in .txt files.

### 3.10. To start Hadoop, run:
```sh
./docker/scripts/run-hadoop.sh
```
This script will start the Hadoop service and ensure it is running and healthy. It will install hdfs with one namenode and two datanodes, yarn with one resourcemanager and two nodemanagers, and mapreduce with one historyserver with postgresql metastore.
Once the services are up and running, you can access the Hadoop Namenode UI at http://localhost:9870 and the Hadoop ResourceManager UI at http://localhost:8088.

## Additional Information

	•	Health Checks: The scripts include health checks to ensure that services are running correctly.
	•	Orphan Containers: Before starting new containers, the scripts will remove any orphan containers to avoid conflicts.
	•	Network Management: The scripts ensure that all services run on the same Docker network for seamless communication.
	•	Logging: Detailed logs are provided to help with troubleshooting and monitoring the status of services.
	•	Git Ignore: Ensure to add '/docker/service-data/' entry to your .gitignore file to prevent committing the volume data and config files.

By following these instructions, you should be able to set up and manage a big data environment on your Mac with ease.

## License

Contributions are welcome! Please fork the repository and submit a pull request for review.
This project is licensed under the MIT License - see the [LICENSE](LICENSE.txt) file for details.