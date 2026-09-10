#!/bin/bash
# Validate Loki: push one test log, then query it back.
# Run from anywhere. Requires curl. Loki must be on localhost:3100.
#
#   chmod +x validate-loki.sh
#   ./validate-loki.sh

set -eu

LOKI_URL="http://localhost:3100"
JOB="test_app"
MSG="hello-from-validate-loki"
# Loki timestamps are nanoseconds (Unix seconds + 9 zeros)
NOW_NS="$(date +%s)000000000"
START_NS="$(($(date +%s) - 60))000000000"

echo "1) Is Loki ready?"
curl -sf "${LOKI_URL}/ready"
echo
echo

echo "2) Push a test log (job=${JOB})"
# POST /loki/api/v1/push is how apps send logs to Loki.
# "stream" = labels (indexed). "values" = [timestamp, log line].
curl -sf -X POST "${LOKI_URL}/loki/api/v1/push" \
  -H "Content-Type: application/json" \
  -d "{
    \"streams\": [{
      \"stream\": {\"job\": \"${JOB}\", \"env\": \"test\"},
      \"values\": [[\"${NOW_NS}\", \"${MSG}\"]]
    }]
  }"
echo "   pushed."
echo

echo "3) Wait 2s for ingest..."
sleep 2

echo "4) Query logs with LogQL: {job=\"${JOB}\"}"
# GET /loki/api/v1/query_range asks Loki for logs in a time window.
RESULT="$(curl -sf -G "${LOKI_URL}/loki/api/v1/query_range" \
  --data-urlencode "query={job=\"${JOB}\"}" \
  --data-urlencode "start=${START_NS}" \
  --data-urlencode "end=${NOW_NS}" \
  --data-urlencode "limit=10")"

echo "${RESULT}"
echo

if echo "${RESULT}" | grep -q "${MSG}"; then
  echo "OK: Loki received, stored, and returned the test log."
else
  echo "FAIL: test log not found. Is Loki up? Try: curl ${LOKI_URL}/ready"
  exit 1
fi
