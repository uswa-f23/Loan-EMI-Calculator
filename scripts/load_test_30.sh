#!/bin/bash
URL="http://localhost:8081/api/emi"
HOST_HEADER="Host: emi.local"

for i in $(seq 1 30); do
  curl -s -X POST "$URL" \
    -H "Content-Type: application/json" \
    -H "$HOST_HEADER" \
    -d '{"principal": 500000, "rate": 12, "months": 24}' \
    | grep -o '"servedBy":"[^"]*"'
done