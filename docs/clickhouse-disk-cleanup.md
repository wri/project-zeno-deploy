# ClickHouse Out of Disk Space Issue

## Context

We use ClickHouse as part of our Langfuse stack for observability and logging. By default, ClickHouse retains system logs (trace logs, query logs, metric logs, etc.) indefinitely without automatic cleanup. This leads to unbounded disk usage growth over time.

**Impact**: When ClickHouse runs out of disk space, Langfuse stops recording any new data until the issue is resolved, causing a complete loss of observability during the outage.

## Immediate Solution (Manual Cleanup)

### 1. Access ClickHouse Pod

Get a shell in the ClickHouse pod:
```bash
kubectl exec -it zeno-clickhouse-shard0-0 -- bash
```

Check disk usage:
```bash
df -h
```

Get the ClickHouse password:
```bash
printenv | grep PASSWORD
```

Connect to ClickHouse client (use the password from above):
```bash
clickhouse-client
```

### 2. Analyze Disk Usage

Identify which tables are using the most space:
```sql
-- See which tables are using the most space
SELECT
    database,
    table,
    formatReadableSize(sum(bytes_on_disk)) as disk_size,
    sum(rows) as rows,
    count() as parts_count
FROM system.parts
GROUP BY database, table
ORDER BY sum(bytes_on_disk) DESC
LIMIT 20;

-- Check for tables with many small parts (fragmentation)
SELECT
    database,
    table,
    count() as parts_count,
    formatReadableSize(sum(bytes_on_disk)) as total_size,
    formatReadableSize(avg(bytes_on_disk)) as avg_part_size
FROM system.parts
GROUP BY database, table
HAVING count() > 100
ORDER BY count() DESC;
```

### 3. Clean Up System Logs

**Note**: `trace_log` is typically the main disk space consumer. Clearing it alone is usually sufficient to free up significant disk space.

Truncate system log tables cluster-wide:
```sql
-- Clean up logs cluster-wide using SYSTEM commands
SYSTEM FLUSH LOGS ON CLUSTER default;

-- Truncate trace_log (usually the biggest space consumer)
TRUNCATE TABLE system.trace_log ON CLUSTER default;

-- Optionally truncate other system tables if more space is needed
TRUNCATE TABLE system.metric_log ON CLUSTER default;
TRUNCATE TABLE system.text_log ON CLUSTER default;
TRUNCATE TABLE system.asynchronous_metric_log ON CLUSTER default;
TRUNCATE TABLE system.latency_log ON CLUSTER default;
TRUNCATE TABLE system.opentelemetry_span_log ON CLUSTER default;
TRUNCATE TABLE system.query_log ON CLUSTER default;
TRUNCATE TABLE system.processors_profile_log ON CLUSTER default;
TRUNCATE TABLE system.part_log ON CLUSTER default;

-- Final flush
SYSTEM FLUSH LOGS ON CLUSTER default;
```

### 4. If Disk is Completely Full

If the cleanup fails due to insufficient disk space, temporarily increase the disk size for all replicas:

```bash
kubectl patch pvc data-zeno-clickhouse-shard0-0 -p '{"spec":{"resources":{"requests":{"storage":"xxGi"}}}}'
kubectl patch pvc data-zeno-clickhouse-shard0-1 -p '{"spec":{"resources":{"requests":{"storage":"xxGi"}}}}'
kubectl patch pvc data-zeno-clickhouse-shard0-2 -p '{"spec":{"resources":{"requests":{"storage":"xxGi"}}}}'
```

After cleanup, verify disk usage has decreased:
```bash
df -h
```

## Long-Term Fix

### Automatic Log Retention Configuration

Configure ClickHouse to disable certain system logs and/or automatically manage system log retention by setting TTL (Time To Live) policies. This should be done via ClickHouse configuration or Langfuse deployment settings.

**Recommended Actions**:

1. **Disable Unnecessary System Log Tables**: Disable system log tables that are not needed for production monitoring to prevent disk growth
   - Reference: [Altinity KB - System Tables Disk Usage](https://kb.altinity.com/altinity-kb-setup-and-maintenance/altinity-kb-system-tables-eat-my-disk/)
   - Reference: [Langfuse ClickHouse discussion](https://github.com/orgs/langfuse/discussions/5687)
   - **`trace_log` is typically the biggest culprit**, often consuming a disproportionately large percentage of disk space
   - Consider disabling: `trace_log`, `part_log`, `processors_profile_log`, `opentelemetry_span_log`, etc.
   - Keep only essential logs like `query_log` with appropriate TTL if needed

2. **Adjust Disk Size**: Provision adequate disk space based on expected log retention period and data volume

3. **Implement Monitoring & Alerts**:
   - Set up disk usage monitoring for ClickHouse pods
   - Create alerts when disk usage exceeds 70-80% threshold
   - Monitor via Kubernetes metrics or ClickHouse system tables

4. **Regular Maintenance**: Schedule periodic log cleanup jobs if disabling the logs and automatic TTL is not sufficient

### Next Steps

- [ ] Review Langfuse documentation for recommended ClickHouse configuration
- [ ] Disable unnecessary system log tables and set TTL policies as required
- [ ] Set up Prometheus/Grafana alerts for ClickHouse disk usage
- [ ] Document the final configuration in deployment documentation
