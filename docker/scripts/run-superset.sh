#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# Function to generate a random secret key
generate_secret_key() {
    openssl rand -base64 42
}

# Function to create the superset configuration file
create_superset_config() {
    local secret_key=$1
    local config_dir="$SCRIPT_DIR/../service-data/superset/configs"
    local config_file="$config_dir/superset_config.py"

    # Ensure the configuration directory exists
    mkdir -p "$config_dir"

    # Create the superset configuration file with the new secret key and Pinot configuration
    cat > "$config_file" <<EOL
# Superset configuration file
SECRET_KEY = '${secret_key}'
ROW_LIMIT = 5000
SUPERSET_WEBSERVER_PORT = 8088

# Database configuration
SQLALCHEMY_DATABASE_URI = 'postgresql://superset:superset@superset_db:5432/superset'

# Pinot configuration
from pinotdb.sqlalchemy import PinotDialect
ADDITIONAL_DATABASES = {
    'apache_pinot': {
        'NAME': 'Apache Pinot',
        'URI': 'pinot://pinot-broker:8099/query?controller=http://pinot-controller:9000/',
        'BACKEND': 'superset.db_engine_specs.pinot.PinotEngineSpec',
    }
}

# Additional configurations can be added here
EOL
}

# Function to install PinotDB connector in the Superset container
install_pinot_connector() {
    echo -e "\n$(timestamp) [INFO] Installing PinotDB connector in the Superset container..."
    docker exec -it superset pip install pinotdb
}

# Function to restart services
restart_services() {
    restart_service "superset_db" "$SCRIPT_DIR/../docker-compose/docker-compose-superset.yml" "superset_db"
    restart_service "superset_cache" "$SCRIPT_DIR/../docker-compose/docker-compose-superset.yml" "superset_cache"
    restart_service "superset" "$SCRIPT_DIR/../docker-compose/docker-compose-superset.yml" "superset"
}

# Function to initialize the database and create an admin user if not exists
initialize_superset() {
    echo -e "\n$(timestamp) [INFO] Initializing Superset..."
    docker exec -it superset superset db upgrade
    if ! docker exec -it superset superset fab list-users | grep -q admin; then
        docker exec -it superset superset fab create-admin \
            --username admin \
            --firstname Superset \
            --lastname Admin \
            --email admin@superset.com \
            --password admin
    else
        echo "$(timestamp) [INFO] Admin user already exists."
    fi
    docker exec -it superset superset init
}

# Main script execution

# Generate a new secret key
SECRET_KEY=$(generate_secret_key)

# Create the superset configuration file with the new secret key and Pinot configuration
create_superset_config "$SECRET_KEY"

# Restart Superset services
restart_services

# Install PinotDB connector in the Superset container
install_pinot_connector

# Initialize the database and create an admin user if not exists
initialize_superset