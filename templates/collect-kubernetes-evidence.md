# Collect Kubernetes Evidence

Collect only the Kubernetes evidence needed to evaluate the scoped hypotheses. Every Kubernetes operation must run as a kubectl command through the attached runner's shell capability. No Ubuntu CLI integration is required. Use the configured shell tool or resolve the runner's advertised execute_command/execute_series tool and inspect its schema; never invent the tool name. Do not search for or use a native Kubernetes integration.

First check the upstream scope and ticket_assessment. If diagnostics_allowed is not explicitly true for this ticket, return a JSON evidence result with status blocked (or invalid_assessment), no observations, and the known blockers, without invoking any tools. This is a completed stage, not a workflow abort. When queries fail due to runner, credentials, or access problems, report operator_blockers, not missing developer detail.

1. Confirm the remote runner, kubectl context, environment, namespace, workload, and time window before querying.
2. Submit one command per shell-tool call. Each command must begin with `kubectl` and must not use `bash`, `sh`, command chaining, substitution, pipes, or redirection.
3. Use only `kubectl get`, `kubectl describe`, `kubectl logs`, `kubectl rollout status`, `kubectl rollout history`, and bounded `kubectl top` operations.
4. Scope queries to the identified namespace and named resources. Avoid cluster-wide enumeration.
5. Check workload readiness, pod lifecycle and restart state, scheduling failures, recent events, service endpoints, deployment rollout state, and relevant resource pressure.
6. Correlate evidence timestamps with the reported incident window.
7. Record stable resource identifiers and concise redacted findings. Separate observed facts from interpretations.
8. Stop if the required query would read a Secret, expose raw ConfigMap content, use `get --raw`, impersonate another identity, or mutate the cluster.

Return observations, evidence references, contradictions, and missing checks. Never execute remediation.
