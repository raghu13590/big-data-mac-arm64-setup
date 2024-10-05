from pyspark.sql import SparkSession

# Initialize a Spark session
spark = SparkSession.builder \
    .appName("HDFS Test") \
    .getOrCreate()

# Create a simple DataFrame
data = [("Alice", 34), ("Bob", 45), ("Catherine", 29)]
columns = ["Name", "Age"]
df = spark.createDataFrame(data, columns)

# Write the DataFrame to HDFS with overwrite mode
hdfs_write_path = "hdfs://namenode:9000/user/spark/output/sample_data.parquet"
df.write.mode("overwrite").parquet(hdfs_write_path)

# Read the DataFrame back from HDFS
df_read = spark.read.parquet(hdfs_write_path)

# Show the data
df_read.show()

# Stop the Spark session
spark.stop()
