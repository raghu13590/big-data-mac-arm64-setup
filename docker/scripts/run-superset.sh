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

    # Create the superset configuration file with the new secret key
    cat > "$config_file" <<EOL
# Superset configuration file
SECRET_KEY = '${secret_key}'
ROW_LIMIT = 5000
SUPERSET_WEBSERVER_PORT = 8088
EOL
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

# Create the superset configuration file with the new secret key
create_superset_config "$SECRET_KEY"

# Restart Superset services
restart_services

# Initialize the database and create an admin user if not exists
initialize_superset