#!/bin/bash
# Host-side timeshift proxy script
# This script runs on the host system and can be called from the container

# Run timeshift with proper privileges and environment
sudo timeshift "$@"
