#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# Create the flink-conf.yaml file
FLINK_CONFIG_DIR="$SCRIPT_DIR/../service-data/flink/configs"
FLINK_CONFIG_FILE="$FLINK_CONFIG_DIR/flink-conf.yaml"

mkdir -p "$FLINK_CONFIG_DIR"

cat > "$FLINK_CONFIG_FILE" <<EOL
blob.server.port: 6124
taskmanager.log.path: /opt/flink/log
taskmanager.memory.process.size: 1024m
jobmanager.web.log.path: /opt/flink/log
env.java.opts: -XX:+UnlockCommercialFeatures-XX:+FlightRecorder-XX:StartFlightRecording=filename=/opt/flink/jfr/taskmanager.jfr
jobmanager.rpc.address: jobmanager
taskmanager.numberOfTaskSlots: 20
jobmanager.web.submit.enable: true
jobmanager.memory.process.size: 1024m
query.server.port: 6125
EOL

if [ "$1" == "--enable-flamegraph" ]; then
  echo "rest.flamegraph.enabled: true" >> "$FLINK_CONFIG_FILE"
fi

# Restart Zookeeper if it's not running
"$SCRIPT_DIR/run-zookeeper.sh"

# Verify if Zookeeper is running
verify_service "zookeeper"

# Restart Flink Job Manager service if it's not running
restart_service "jobmanager" "$SCRIPT_DIR/../docker-compose/docker-compose-flink.yml" "flink-jobmanager"

# Restart Flink Task Manager service if it's not running
restart_service "taskmanager" "$SCRIPT_DIR/../docker-compose/docker-compose-flink.yml" "flink-taskmanager"