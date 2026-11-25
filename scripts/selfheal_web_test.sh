#!/bin/bash
URL="http://localhost:8081/api/emi"
HOST_HEADER="Host: emi.local"
for i in $(seq 1 40); do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$URL" \
    -H "Content-Type: application/json" -H "$HOST_HEADER" \
    -d '{"principal": 500000, "rate": 12, "months": 24}')
  echo "request $i: HTTP $CODE"
  sleep 0.5
done