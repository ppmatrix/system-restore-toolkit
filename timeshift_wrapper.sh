#!/bin/bash
# This script runs timeshift on the host system from within a Docker container

# Execute timeshift command on the host using docker exec
# We need to run this from the host, so we use nsenter to enter host namespaces
exec nsenter -t 1 -m -p -- timeshift "$@"
