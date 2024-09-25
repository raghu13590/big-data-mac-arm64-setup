#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install curl inside the spark-master container without showing logs
install_curl() {
    echo "Installing curl in spark-master container..."
    docker exec -u root -it spark-master bash -c "apt-get update > /dev/null 2>&1 && apt-get install -y curl > /dev/null 2>&1"
    if [ $? -eq 0 ]; then
        echo "curl installed successfully!"
    else
        echo "Failed to install curl!" >&2
        exit 1
    fi
}

# Helper function to run a Spark job and check its success
run_spark_job() {
    local mode=$1
    local master=$2
    local test_description=$3

    echo "Running test: $test_description"

    # Run the example job
    docker exec -it spark-master bash -c \
    "spark-submit --class org.apache.spark.examples.SparkPi \
    --master $master /opt/bitnami/spark/examples/jars/spark-examples_2.12-3.5.2.jar 10" > /tmp/spark_test_output.txt 2>&1

    # Check if the job succeeded by looking for output containing "Pi is roughly"
    if grep -q "Pi is roughly" /tmp/spark_test_output.txt; then
        echo "Test passed: $test_description"
    else
        echo "Test failed: $test_description"
        cat /tmp/spark_test_output.txt
    fi
}

# Check if YARN is available by using curl to check the ResourceManager's web UI
is_yarn_available() {
    if docker exec -it spark-master bash -c "curl -s -L -o /dev/null -w '%{http_code}' resourcemanager:8088" | grep -q "200"; then
        return 0  # YARN is up
    else
        return 1  # YARN is not available
    fi
}

echo "Running Spark tests..."

# Install curl if it's not available
docker exec -it spark-master bash -c "which curl > /dev/null 2>&1"
if [ $? -ne 0 ]; then
    install_curl
else
    echo "curl is already installed."
fi

# Test in standalone mode
run_spark_job "standalone" "spark://spark-master:7077" "Standalone mode (Spark cluster)"

# Test in local mode (runs Spark locally with a single worker thread)
run_spark_job "local" "local" "Local mode (1 core)"

# Test in local[*] mode (runs Spark locally with all available cores)
run_spark_job "local[*]" "local[*]" "Local mode (all cores)"

# Check if YARN is available before running YARN-related tests
if is_yarn_available; then
    echo "YARN is available, running YARN tests..."
    # Test with YARN in client mode (if YARN is available)
    run_spark_job "yarn-client" "yarn" "YARN client mode (YARN cluster)"

    # Test with YARN in cluster mode (if YARN is available)
    run_spark_job "yarn-cluster" "yarn" "YARN cluster mode (YARN cluster)"
else
    echo "YARN is not available, skipping YARN tests."
fi

echo "All tests completed!"