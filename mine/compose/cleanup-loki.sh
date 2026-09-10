#!/bin/bash
# Remove the test logs created by validate-loki.sh (job=test_app).
# Loki delete is a request to the compactor — it may take a few minutes.
#
#   chmod +x cleanup-loki.sh
#   ./cleanup-loki.sh

set -euo pipefail

LOKI_URL="http://localhost:3100"
JOB="test_app"

# Delete API wants RFC3339 start/end. Works on Mac (-v) and Linux (-d).
if date -u -v-24H +"%Y-%m-%dT%H:%M:%SZ" >/dev/null 2>&1; then
  START="$(date -u -v-24H +"%Y-%m-%dT%H:%M:%SZ")"
else
  START="$(date -u -d '24 hours ago' +"%Y-%m-%dT%H:%M:%SZ")"
fi
END="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

echo "1) Request delete of {job=\"${JOB}\"} from ${START} to ${END}"
# POST /loki/api/v1/delete queues a delete; it does not wipe instantly.
curl -sf -X POST "${LOKI_URL}/loki/api/v1/delete" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "query={job=\"${JOB}\"}" \
  --data-urlencode "start=${START}" \
  --data-urlencode "end=${END}"
echo
echo "   delete request accepted."
echo

echo "2) Pending delete requests:"
curl -sf "${LOKI_URL}/loki/api/v1/delete"
echo
echo

echo "Note: Loki's compactor applies deletes on its interval (often minutes)."
echo "Re-run validate-loki.sh later if you need a fresh test stream."
