#!/bin/bash
# Usage: ./profile_run.sh <replicas> <rate> <duration>
REPLICAS=$1
RATE=$2
DURATION=${3:-60}
OUTDIR=~/emi-k8s-assignment/results
TAG="r${REPLICAS}_rate${RATE}"

PODCSV="$OUTDIR/pods_${TAG}.csv"
HOSTCSV="$OUTDIR/host_${TAG}.csv"

echo "timestamp,pod,cpu,memory" > "$PODCSV"
echo "timestamp,cpu_user,cpu_system,cpu_idle" > "$HOSTCSV"

END=$((SECONDS + DURATION))

# Pod metrics every 15s
(
  while [ $SECONDS -lt $END ]; do
    TS=$(date +%s)
    kubectl top pods -n emi --no-headers 2>/dev/null | grep emi-web | while read -r line; do
      POD=$(echo "$line" | awk '{print $1}')
      CPU=$(echo "$line" | awk '{print $2}')
      MEM=$(echo "$line" | awk '{print $3}')
      echo "$TS,$POD,$CPU,$MEM" >> "$PODCSV"
    done
    sleep 15
  done
) &
PODPID=$!

# Host CPU every 1s using /proc/stat (no extra package needed)
(
  prev_idle=0
  prev_total=0
  while [ $SECONDS -lt $END ]; do
    read -r cpu user nice system idle iowait irq softirq steal _ < /proc/stat
    total=$((user+nice+system+idle+iowait+irq+softirq+steal))
    idle_all=$((idle+iowait))
    if [ "$prev_total" -ne 0 ]; then
      dtotal=$((total-prev_total))
      didle=$((idle_all-prev_idle))
      if [ "$dtotal" -gt 0 ]; then
        busy=$(( (dtotal-didle) * 100 / dtotal ))
      else
        busy=0
      fi
      echo "$(date +%s),${busy},NA,$((100-busy))" >> "$HOSTCSV"
    fi
    prev_idle=$idle_all
    prev_total=$total
    sleep 1
  done
) &
HOSTPID=$!

wait $PODPID $HOSTPID
echo "Profiling done: $TAG"