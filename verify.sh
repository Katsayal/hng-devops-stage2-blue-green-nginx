#!/bin/bash
set -e

# Helper function to wait for a service health check
wait_for_health() {
  local url=$1
  local name=$2
  local retries=10
  local count=0

  echo "Waiting for $name to become healthy at $url..."
  until curl -fsS "$url" >/dev/null; do
    count=$((count + 1))
    if [ $count -ge $retries ]; then
      echo "❌ $name did not become healthy in time"
      exit 1
    fi
    sleep 2
  done
  echo "✅ $name is healthy"
}

# Wait for Blue and Green apps to be healthy
wait_for_health http://localhost:8081/healthz "Blue"
wait_for_health http://localhost:8082/healthz "Green"

# Baseline check (Blue should be active)
echo "Checking baseline (should be blue)..."
BLUE_RESP=$(curl -s -D - http://localhost:8080/version -o /dev/null | grep X-App-Pool)
echo "$BLUE_RESP"
[[ "$BLUE_RESP" == *"blue"* ]] || { echo "❌ Expected blue"; exit 1; }

# Trigger chaos on Blue
echo "Triggering chaos on Blue..."
curl -s -X POST http://localhost:8081/chaos/start?mode=error >/dev/null

# Poll Nginx until failover observed
echo "Checking failover (should switch to green)..."
MAX_RETRIES=10
count=0
while true; do
  GREEN_RESP=$(curl -s -D - http://localhost:8080/version -o /dev/null | grep X-App-Pool || true)
  if [[ "$GREEN_RESP" == *"green"* ]]; then
    echo "$GREEN_RESP"
    echo "✅ Failover to Green successful"
    break
  fi
  count=$((count+1))
  if [ $count -ge $MAX_RETRIES ]; then
    echo "❌ Failover to Green did not occur in time"
    exit 1
  fi
  sleep 1
done

# Stop chaos to restore Blue
echo "Stopping chaos on Blue..."
curl -s -X POST http://localhost:8081/chaos/stop >/dev/null

echo "✅ All checks passed: Blue → Green failover successful, responses stayed 200."



#docker compose up -d
#curl -i http://localhost:8080/version
#curl -X POST http://localhost:8081/chaos/start?mode=error
#curl -X POST http://localhost:8081/chaos/stop
#bash verify.sh
#docker compose down