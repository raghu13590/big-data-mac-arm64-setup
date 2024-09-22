#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to execute a command in a container
execute_in_container() {
    local container_name="$1"
    local command="$2"
    docker exec -it "$container_name" bash -c "$command"
}

# Function to test HDFS
test_hdfs() {
    echo "Testing HDFS..."
    execute_in_container namenode "hdfs dfs -mkdir -p /test/input"
    execute_in_container namenode "echo 'Hello, World!' | hdfs dfs -put - /test/input/hello.txt"
    execute_in_container namenode "hdfs dfs -cat /test/input/hello.txt"
    execute_in_container namenode "hdfs dfs -rm -r /test"
}

# Function to test YARN
test_yarn() {
    echo "Testing YARN..."
    execute_in_container resourcemanager "yarn jar /opt/hadoop-3.3.6/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar pi 2 10"
}

# Function to test Hive
test_hive() {
    echo "Testing Hive..."
    execute_in_container hiveserver2 "hive -e 'CREATE DATABASE IF NOT EXISTS test_db;'"
    execute_in_container hiveserver2 "hive -e 'CREATE TABLE IF NOT EXISTS test_db.test_table (id INT, name STRING);'"
    execute_in_container hiveserver2 "hive -e 'INSERT INTO test_db.test_table VALUES (1, \"John\"), (2, \"Jane\");'"
    execute_in_container hiveserver2 "hive -e 'SELECT * FROM test_db.test_table;'"
    execute_in_container hiveserver2 "hive -e 'DROP TABLE test_db.test_table;'"
    execute_in_container hiveserver2 "hive -e 'DROP DATABASE test_db;'"
}

# Check if Docker is installed
if ! command_exists docker; then
    echo "Docker is not installed. Please install Docker and try again."
    exit 1
fi

# Check if Docker Compose is installed
if ! command_exists docker-compose; then
    echo "Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

# Test HDFS
test_hdfs

# Test YARN
test_yarn

# Test Hive
test_hive

echo "All tests completed successfully!"