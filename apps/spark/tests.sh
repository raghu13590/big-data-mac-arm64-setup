#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Initialize test statuses
hdfs_test_status="not run"
standalone_test_status="not run"
local_test_status="not run"
local_all_cores_test_status="not run"
yarn_client_test_status="not run"
yarn_cluster_test_status="not run"

# Helper function to run a command and check its success
run_command() {
    local command="$1"
    local description="$2"
    local output_file="/tmp/command_output.txt"

    docker exec -it spark-master bash -c "$command" > "$output_file" 2>&1
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        return 0
    else
        return 1
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
    run_command "spark-submit --master spark://spark-master:7077 /opt/spark/hdfs_test.py" \
    "HDFS read/write test with PySpark"

    # Update test status
    if [ $? -eq 0 ]; then
        hdfs_test_status="passed"
    else
        hdfs_test_status="failed"
    fi
}

# Run SparkPi job without output to test basic Spark job submission
run_spark_job() {
    local mode="$1"
    local master="$2"
    local test_description="$3"

    echo "Running $test_description"

    run_command "spark-submit --class org.apache.spark.examples.SparkPi \
    --master $master \
    --conf spark.eventLog.enabled=false \
    /opt/spark/examples/jars/spark-examples_2.12-3.2.1.jar 10" "$test_description"

    # Update test status based on the description
    case "$test_description" in
        "Standalone mode (Spark cluster)")
            [ $? -eq 0 ] && standalone_test_status="passed" || standalone_test_status="failed"
            ;;
        "Local mode (1 core)")
            [ $? -eq 0 ] && local_test_status="passed" || local_test_status="failed"
            ;;
        "Local mode (all cores)")
            [ $? -eq 0 ] && local_all_cores_test_status="passed" || local_all_cores_test_status="failed"
            ;;
        "YARN client mode (YARN cluster)")
            [ $? -eq 0 ] && yarn_client_test_status="passed" || yarn_client_test_status="failed"
            ;;
        "YARN cluster mode (YARN cluster)")
            [ $? -eq 0 ] && yarn_cluster_test_status="passed" || yarn_cluster_test_status="failed"
            ;;
    esac
}

# Create Spark history directory
create_spark_history_dir() {
    run_command "mkdir -p /opt/spark/history && chmod 777 /opt/spark/history" "Creating Spark history directory"
}

echo ""
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

# Display test results
echo ""
echo "Test Results:"
echo "HDFS read/write test: $hdfs_test_status"
echo "Standalone mode test: $standalone_test_status"
echo "Local mode (1 core) test: $local_test_status"
echo "Local mode (all cores) test: $local_all_cores_test_status"
echo "YARN client mode test: $yarn_client_test_status"
echo "YARN cluster mode test: $yarn_cluster_test_status"

echo "All tests completed!"
