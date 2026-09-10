# Loki metrics in Prometheus (novice guide)

Prometheus scrapes Loki at `loki:3100` (see `prometheus.yaml`, job `loki`).
Open http://localhost:9090 → Graph → paste a query → Execute.

A **counter** only goes up. Wrap it in `rate(...[5m])` to get “per second over the last 5 minutes”.

## After you run `validate-loki.sh`

| What you want to know | PromQL | Good result |
|---|---|---|
| Can Prometheus see Loki? | `up{job="loki"}` | `1` |
| Are log lines arriving? | `rate(loki_distributor_lines_received_total[5m])` | `> 0` after a push |
| How much data (bytes/s)? | `rate(loki_distributor_bytes_received_total[5m])` | `> 0` after a push |
| Active log streams in memory | `loki_ingester_streams` | `>= 1` after a push |
| Failed HTTP requests | `rate(loki_request_duration_seconds_count{status_code=~"5.."}[5m])` | `0` |

## How to run the scripts

From `mine/compose` (or copy them to the docker host):

```bash
chmod +x validate-loki.sh cleanup-loki.sh
./validate-loki.sh    # send one log, confirm Loki stored it
./cleanup-loki.sh     # ask Loki to delete job=test_app logs
```

`validate-loki.sh` uses Loki’s **push API** (write) then **query_range** (read).
`cleanup-loki.sh` uses Loki’s **delete API** (compactor; not instant).
