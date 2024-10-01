#!/bin/bash
# entrypoint.sh

# Start Spark master
$SPARK_HOME/sbin/start-master.sh

# Start Spark worker
$SPARK_HOME/sbin/start-worker.sh spark://$(hostname):7077

# Keep the container running
tail -f /dev/null