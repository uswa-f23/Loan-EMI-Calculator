#!/bin/bash
# Runs all 5 rates for a GIVEN replica count (call this once per replica count)
REPLICAS=$1
RATES=(10 25 50 100 200)
DURATION=60

for RATE in "${RATES[@]}"; do
  echo "=== Starting replicas=$REPLICAS rate=$RATE ==="
  ./run_one.sh "$RATE" "$REPLICAS" "$DURATION"
  echo "=== Cooling down 5s ==="
  sleep 5
done