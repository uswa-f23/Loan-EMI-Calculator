#!/bin/bash
OUTDIR=~/emi-k8s-assignment/results
HPACSV="$OUTDIR/hpa_test.csv"
echo "timestamp,replicas,target_cpu_pct,current_cpu_pct" > "$HPACSV"

PAYLOAD="/tmp/payload.json"
cat > "$PAYLOAD" << 'PLEOF'
{"principal": 500000, "rate": 12, "months": 24}
PLEOF

# Background: sample HPA state every 15s for 10 minutes (600s)
(
  END=$((SECONDS + 600))
  while [ $SECONDS -lt $END ]; do
    TS=$(date +%s)
    HPALINE=$(kubectl get hpa emi-web -n emi --no-headers 2>/dev/null)
    REPLICAS=$(echo "$HPALINE" | awk '{print $7}')
    TARGETS=$(echo "$HPALINE" | awk '{print $3}')
    echo "$TS,$REPLICAS,$TARGETS," >> "$HPACSV"
    sleep 15
  done
) &
MONPID=$!

echo "=== Phase 1: 10 req/s for 2 minutes ==="
ab -n 1200 -c 10 -t 120 -H "Host: emi.local" -T "application/json" -p "$PAYLOAD" http://localhost:8081/api/emi > "$OUTDIR/hpa_phase1.log" 2>&1

echo "=== Phase 2: 100 req/s for 5 minutes ==="
ab -n 30000 -c 60 -t 300 -H "Host: emi.local" -T "application/json" -p "$PAYLOAD" http://localhost:8081/api/emi > "$OUTDIR/hpa_phase2.log" 2>&1

echo "=== Phase 3: 10 req/s for 3 minutes ==="
ab -n 1800 -c 10 -t 180 -H "Host: emi.local" -T "application/json" -p "$PAYLOAD" http://localhost:8081/api/emi > "$OUTDIR/hpa_phase3.log" 2>&1

wait $MONPID
echo "=== HPA test complete ==="