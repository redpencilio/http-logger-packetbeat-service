#!/bin/sh
# Script to check whether the container can still reach logstash.
# If it can't the container is killed.
# This is a bit of a hack, mostly because Packetbeat is a little
# badly documented, and its Dockerfile isn't available.
# Also note that Elastic containers seem to be based on CentOS,
# which uses `dash` as their `sh`. So try to avoid bash-isms if
# you modify this script!

trap "exit 133" INT TERM # Exit on signal

/usr/local/bin/docker-entrypoint -environment container & # Taken from `docker inspect`-ing a regular Packetbeat container.
                                                          # Note the & to run in the background.

packetbeat=$! # Get the PID

# Basic exponential backoff algorithm.
backoff=2
while true; do
    if ! ps -p "$packetbeat" > /dev/null 2>&1; then # If Packetbeat itself has exited, die.
        exit 24
    fi
    if ping -q -c 1 -w 1 logstash > /dev/null; then # Deadline of 1 second should be enough if logstash is on the same host.
        backoff=2
    else
        if [ $backoff -ge 32 ]; then
            echo "!!Cannot connect to Logstash, exiting.!!"
            exit 25
        else
            backoff=$((2 * backoff))
        fi
    fi
    # Sleep and wait so we can trap signals
    sleep "$backoff" &
    wait $!
done
