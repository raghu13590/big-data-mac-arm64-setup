#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Helper function to run a command and check its success
run_command() {
    local command="$1"
    local description="$2"
    local output_file="/tmp/command_output.txt"

    echo "Running test: $description"
    docker exec -it spark-master bash -c "$command" > "$output_file" 2>&1
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo "Test passed: $description"
    else
        echo "Test failed: $description"
        echo "Command output:"
        cat "$output_file"
    fi
}

# Test HDFS read/write using spark-submit with Python script
test_hdfs_read_write_with_spark() {
    echo "Running HDFS read/write test with Spark"

    # Use the relative path to hdfs_test.py
    docker cp "$SCRIPT_DIR/hdfs_test.py" spark-master:/opt/spark/hdfs_test.py

    # Check if the file is copied correctly
    docker exec -it spark-master bash -c "ls /opt/spark/hdfs_test.py"

    # Run the Python script using spark-submit
    run_command \
    "spark-submit --master spark://spark-master:7077 /opt/spark/hdfs_test.py" \
    "HDFS read/write test with PySpark"
}

# Run SparkPi job without output to test basic Spark job submission
run_spark_job() {
    local mode="$1"
    local master="$2"
    local test_description="$3"

    run_command "spark-submit --class org.apache.spark.examples.SparkPi \
    --master $master \
    --conf spark.eventLog.enabled=false \
    /opt/spark/examples/jars/spark-examples_2.12-3.4.3.jar 10" "$test_description"
}

# Create Spark history directory
create_spark_history_dir() {
    run_command "mkdir -p /opt/spark/history && chmod 777 /opt/spark/history" "Creating Spark history directory"
}

echo "Running Spark tests..."

# Create Spark history directory
create_spark_history_dir

# Test HDFS read and write using Spark (via Python script)
test_hdfs_read_write_with_spark

# Test in standalone mode
run_spark_job "standalone" "spark://spark-master:7077" "Standalone mode (Spark cluster)"

# Test in local mode (runs Spark locally with a single worker thread)
run_spark_job "local" "local" "Local mode (1 core)"

# Test in local[*] mode (runs Spark locally with all available cores)
run_spark_job "local[*]" "local[*]" "Local mode (all cores)"

# Check if YARN is available before running YARN-related tests
if docker exec -it spark-master bash -c "curl -s -L -o /dev/null -w '%{http_code}' resourcemanager:8088" | grep -q "200"; then
    echo "YARN is available, running YARN tests..."
    # Test with YARN in client mode
    run_spark_job "yarn" "yarn --deploy-mode client" "YARN client mode (YARN cluster)"

    # Test with YARN in cluster mode
    run_spark_job "yarn-cluster" "yarn --deploy-mode cluster" "YARN cluster mode (YARN cluster)"
else
    echo "YARN is not available, skipping YARN tests."
fi

echo "All tests completed!"
