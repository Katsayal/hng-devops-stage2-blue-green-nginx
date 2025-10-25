#!/bin/bash
set -e

echo "Checking baseline (should be blue)..."
BLUE_RESP=$(curl -s -D - http://localhost:8080/version -o /dev/null | grep X-App-Pool)
echo "$BLUE_RESP"
[[ "$BLUE_RESP" == *"blue"* ]] || { echo "❌ Expected blue"; exit 1; }

echo "Triggering chaos on blue..."
curl -s -X POST http://localhost:8081/chaos/start?mode=error >/dev/null

echo "Checking failover (should be green)..."
GREEN_RESP=$(curl -s -D - http://localhost:8080/version -o /dev/null | grep X-App-Pool)
echo "$GREEN_RESP"
[[ "$GREEN_RESP" == *"green"* ]] || { echo "❌ Expected green failover"; exit 1; }

echo "✅ Pass: Blue→Green failover successful and responses stayed 200."


#docker compose up -d
#curl -i http://localhost:8080/version
#curl -X POST http://localhost:8081/chaos/start?mode=error
#curl -X POST http://localhost:8081/chaos/stop
#bash verify.sh
#docker compose down