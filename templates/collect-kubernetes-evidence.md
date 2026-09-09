# Collect Kubernetes Evidence

Collect only the Kubernetes evidence needed to evaluate the scoped hypotheses.

1. Confirm the target cluster context, environment, namespace, workload, and time window before querying.
2. Use list, get, describe, events, logs, previous logs, rollout status, and rollout history operations only.
3. Check workload readiness, pod lifecycle and restart state, scheduling failures, recent events, service endpoints, deployment rollout state, and relevant resource pressure.
4. Correlate evidence timestamps with the reported incident window.
5. Record stable resource identifiers and concise redacted findings. Separate observed facts from interpretations.
6. Stop if the required query would read a Secret, expose raw ConfigMap content, or mutate the cluster.

Return observations, evidence references, contradictions, and missing checks. Never execute remediation.
