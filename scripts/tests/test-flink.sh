#!/bin/bash

# Function to execute a command in a container and capture the output
execute_in_container() {
    local container_name="$1"
    local command="$2"
    docker exec -i "$container_name" bash -c "$command"
}

# Function to check if Yarn is running
check_yarn_running() {
    local output
    output=$(execute_in_container flink-jobmanager "curl -sf http://resourcemanager:8088/ws/v1/cluster/info")
    if echo "$output" | grep -q "ResourceManager"; then
        return 0
    else
        echo "Yarn ResourceManager is not running."
        return 1
    fi
}

# Function to test Flink JobManager in different modes
test_jobmanager() {
    local mode="$1"
    local output
    echo "Running Flink JobManager test in $mode mode..."
    case $mode in
        local)
            output=$(execute_in_container flink-jobmanager "flink run /opt/flink/examples/streaming/WordCount.jar")
            ;;
        yarn-client)
            output=$(execute_in_container flink-jobmanager "export HADOOP_CLASSPATH=\$(hadoop classpath) && flink run -m yarn-cluster /opt/flink/examples/streaming/WordCount.jar")
            ;;
        yarn-cluster)
            output=$(execute_in_container flink-jobmanager "export HADOOP_CLASSPATH=\$(hadoop classpath) && flink run -m yarn-cluster /opt/flink/examples/streaming/WordCount.jar")
            ;;
        *)
            echo "Unknown mode: $mode"
            return 1
            ;;
    esac
    if echo "$output" | grep -q "Job has been submitted with JobID"; then
        return 0
    else
        echo "JobManager test output in $mode mode: $output"
        return 1
    fi
}

# Function to test Flink TaskManager
test_taskmanager() {
    echo "Running Flink TaskManager test..."
    local output=$(execute_in_container flink-jobmanager "curl -sf http://localhost:8074/taskmanagers | grep 'taskmanagers'")
    if echo "$output" | grep -q "taskmanagers"; then
        return 0
    else
        echo "TaskManager test output: $output"
        return 1
    fi
}

# Initialize test status
jobmanager_local_test_status="not run"
jobmanager_yarn_client_test_status="not run"
jobmanager_yarn_cluster_test_status="not run"
taskmanager_test_status="not run"

# Check if Yarn is running
yarn_running=false
if check_yarn_running; then
    yarn_running=true
fi

# Run JobManager tests in different modes
echo ""
echo "Running tests..."
if test_jobmanager "local"; then
    jobmanager_local_test_status="passed"
else
    jobmanager_local_test_status="failed"
fi

if [ "$yarn_running" = true ]; then
    if test_jobmanager "yarn-client"; then
        jobmanager_yarn_client_test_status="passed"
    else
        jobmanager_yarn_client_test_status="failed"
    fi

    if test_jobmanager "yarn-cluster"; then
        jobmanager_yarn_cluster_test_status="passed"
    else
        jobmanager_yarn_cluster_test_status="failed"
    fi
else
    echo "Skipping Yarn tests as Yarn is not running."
fi

# Run TaskManager test
if test_taskmanager; then
    taskmanager_test_status="passed"
else
    taskmanager_test_status="failed"
fi

# Display test results
echo ""
echo "Test Results:"
echo "JobManager local mode test: $jobmanager_local_test_status"
echo "JobManager YARN client mode test: $jobmanager_yarn_client_test_status"
echo "JobManager YARN cluster mode test: $jobmanager_yarn_cluster_test_status"
echo "TaskManager test: $taskmanager_test_status"