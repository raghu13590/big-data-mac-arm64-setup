#!/bin/bash

# Health check script for Pinot components

check_controller() {
    curl -f -s http://localhost:9000/health > /dev/null 2>&1
    return $?
}

check_broker() {
    curl -f -s http://localhost:8099/health > /dev/null 2>&1
    return $?
}

check_server() {
    curl -f -s http://localhost:8097/health > /dev/null 2>&1
    return $?
}

check_minion() {
    curl -f -s http://localhost:9514/health > /dev/null 2>&1
    return $?
}

# Determine which component to check based on environment variable
case "${PINOT_COMPONENT}" in
    controller)
        check_controller
        ;;
    broker)
        check_broker
        ;;
    server)
        check_server
        ;;
    minion)
        check_minion
        ;;
    *)
        echo "Unknown component: ${PINOT_COMPONENT}"
        exit 1
        ;;
esac

exit $?