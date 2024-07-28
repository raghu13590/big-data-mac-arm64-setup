# Big Data Mac ARM64 Setup

This project sets up a big data environment on a Mac with ARM64 architecture using Docker. It includes scripts to manage and run Zookeeper, Pinot, and Superset services.

## Overview

This project provides a streamlined way to set up and manage a big data environment. It includes Docker Compose files for setting up Zookeeper, Pinot, and Superset, along with shell scripts to manage these services, ensuring they run correctly and efficiently.

### Features

- **Docker Compose Integration**: Easily manage services using Docker Compose.
- **Health Checks**: Automatically verify that services are healthy.
- **Orphan Container Cleanup**: Remove orphan containers before starting new ones.
- **Network Management**: Ensure services are on the same Docker network.
- **Ease of Use**: Scripts can be run from any directory.

## Prerequisites

- Docker
- Docker Compose
- Bash

## Setup Instructions

### 1. Clone the Repository

```sh
git clone https://github.com/your-repo/big-data-mac-arm64-setup.git
cd big-data-mac-arm64-setup
```

###  2. Make Scripts Executable
Ensure the scripts have executable permissions:
```sh
chmod +x docker/scripts/*.sh
```

### 3. Running the Services

### 3.1. To start Zookeeper, run:
This script will start the Zookeeper service and ensure it is running and healthy.
```sh
./docker/scripts/run-zookeeper.sh
```

### 3.2. To start Pinot, run:
This script will start the Pinot controller, broker, and server services, ensuring they are running and healthy.
```sh
./docker/scripts/run-pinot.sh
```
Once the services are up and running, you can access Apache Pinot at http://localhost:9000.

### 3.3. To start Superset, run:
This script will start the Superset service, generate a random secret key, and ensure the service is running and healthy.
```sh
./docker/scripts/run-superset.sh
```
Once the services are up and running, you can access Apache Superset at http://localhost:8088.

## Additional Information

	•	Health Checks: The scripts include health checks to ensure that services are running correctly.
	•	Orphan Containers: Before starting new containers, the scripts will remove any orphan containers to avoid conflicts.
	•	Network Management: The scripts ensure that all services run on the same Docker network for seamless communication.
	•	Logging: Detailed logs are provided to help with troubleshooting and monitoring the status of services.
	•	Git Ignore: Ensure to add '/docker/service-data/' entry to your .gitignore file to prevent committing the volume data and config files.

By following these instructions, you should be able to set up and manage a big data environment on your Mac with ease.

## License

Contributions are welcome! Please fork the repository and submit a pull request for review.
This project is licensed under the MIT License - see the [LICENSE](LICENSE.txt) file for details.