#!/bin/bash

# Copy the JAR file into the Spark master container
docker cp ./spark-app/JavaSpark-1.0-SNAPSHOT.jar spark-master:/tmp/JavaSpark-1.0-SNAPSHOT.jar

# Submit the Spark job
docker exec -it spark-master spark-submit --class mrpowers.javaspark.Main --master spark://spark-master:7077 /tmp/JavaSpark-1.0-SNAPSHOT.jar