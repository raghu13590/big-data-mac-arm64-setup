#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to execute a command in a container and capture the output
execute_in_container() {
    local container_name="$1"
    local command="$2"
    docker exec -i "$container_name" bash -c "$command"
}

# Function to test HDFS
test_hdfs() {
    echo "Running HDFS test..."
    execute_in_container namenode "hdfs dfs -mkdir -p /test/input"
    execute_in_container namenode "echo 'Hello, World!' | hdfs dfs -put - /test/input/hello.txt"
    local output=$(execute_in_container namenode "hdfs dfs -cat /test/input/hello.txt")
    if [ "$output" == "Hello, World!" ]; then
        return 0
    else
        return 1
    fi
    execute_in_container namenode "hdfs dfs -rm -r /test"
}

# Function to test YARN
test_yarn() {
    echo "Running YARN test..."
    local output=$(execute_in_container resourcemanager "yarn jar /opt/hadoop-3.3.6/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar pi 2 10")
    if echo "$output" | grep -q "Estimated value of Pi is"; then
        return 0
    else
        return 1
    fi
}

# Function to test Hive
test_hive() {
    echo "Running Hive test..."
    local temp_log=$(mktemp)

    # Connect to HiveServer2 and create a test database
    docker exec -i hiveserver2 beeline -u jdbc:hive2://hiveserver2:10000 -n hive -p hive \
    -e "CREATE DATABASE IF NOT EXISTS test_db;" >> "$temp_log" 2>&1

    # Create a test table and insert sample data
    docker exec -i hiveserver2 beeline -u jdbc:hive2://hiveserver2:10000 -n hive -p hive \
    -e "USE test_db; CREATE TABLE IF NOT EXISTS test_table (id INT, name STRING); \
    INSERT INTO test_table VALUES (1, 'John'), (2, 'Jane');" >> "$temp_log" 2>&1

    # Query the test table and verify the output
    output=$(docker exec -i hiveserver2 beeline -u jdbc:hive2://hiveserver2:10000 -n hive -p hive \
    -e "SELECT * FROM test_db.test_table;")

    if echo "$output" | grep -q "John"; then
        return 0
    else
        return 1
    fi

    # Clean up the test table and database
    docker exec -i hiveserver2 beeline -u jdbc:hive2://hiveserver2:10000 -n hive -p hive \
    -e "DROP TABLE IF EXISTS test_db.test_table; DROP DATABASE IF EXISTS test_db;" >> "$temp_log" 2>&1

    rm "$temp_log"
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

# Initialize test status
hdfs_test_status="not run"
yarn_test_status="not run"
hive_test_status="not run"

# Run HDFS test
echo "Running tests..."
if test_hdfs; then
    hdfs_test_status="passed"
else
    hdfs_test_status="failed"
fi

# Run YARN test
if test_yarn; then
    yarn_test_status="passed"
else
    yarn_test_status="failed"
fi

# Run Hive test
if test_hive; then
    hive_test_status="passed"
else
    hive_test_status="failed"
fi

# Display test results
echo ""
echo "Test Results:"
echo "HDFS test: $hdfs_test_status"
echo "YARN test: $yarn_test_status"
echo "Hive test: $hive_test_status"
