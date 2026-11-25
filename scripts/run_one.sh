#!/bin/bash
RATE=$1
REPLICAS=$2
DURATION=${3:-60}

./profile_run.sh "$REPLICAS" "$RATE" "$DURATION" &
PROFPID=$!

./run_test.sh "$RATE" "$REPLICAS" "$DURATION"

wait $PROFPID
echo "=== Completed rate=$RATE replicas=$REPLICAS ==="