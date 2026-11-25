#!/bin/bash
RATE=$1
REPLICAS=$2
DURATION=${3:-60}
OUTDIR=~/emi-k8s-assignment/results
TAG="r${REPLICAS}_rate${RATE}"

mkdir -p "$OUTDIR"

PAYLOAD="/tmp/payload.json"
cat > "$PAYLOAD" << 'PLEOF'
{"principal": 500000, "rate": 12, "months": 24}
PLEOF

TOTAL=$((RATE*DURATION))
# Scale concurrency with rate so throughput actually approaches the target rate
CONCURRENCY=$RATE
if [ "$CONCURRENCY" -lt 5 ]; then CONCURRENCY=5; fi
if [ "$CONCURRENCY" -gt 150 ]; then CONCURRENCY=150; fi

ab -n "$TOTAL" -c "$CONCURRENCY" -t "$DURATION" \
  -H "Host: emi.local" \
  -T "application/json" \
  -p "$PAYLOAD" \
  http://localhost:8081/api/emi \
  > "$OUTDIR/ab_${TAG}.log" 2>&1

echo "Done: $TAG"