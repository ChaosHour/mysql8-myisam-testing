#!/bin/bash
set -e

echo "Starting custom entrypoint script..."

# Handle SIGTERM
_term() {
    echo "Caught SIGTERM signal!"
    if [ ! -z "$child" ]; then
        kill -TERM "$child"
    fi
}
trap _term SIGTERM

# Debug info
echo "MySQL Version: $(mysqld --version)"
echo "Configuration files:"
ls -la /etc/mysql/conf.d/

# Start MySQL with error logging
echo "Starting MySQL server..."
/usr/local/bin/docker-entrypoint.sh mysqld --console 2>&1 &
child=$!

# Wait for MySQL to start or fail
wait "$child"
exit_status=$?
echo "MySQL process exited with status: $exit_status"
exit $exit_status