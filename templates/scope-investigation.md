# Scope Frontdoor Investigation

Normalize the input supplied by the upstream coordinator before using infrastructure tools.

1. Preserve `ticket_key` and summarize the reported symptom without inventing missing facts.
2. Determine the service, environment, namespace, affected users, and incident time window from the supplied fields.
3. Search the existing workspace knowledge base for the most relevant issue patterns and diagnostic procedures.
4. Select no more than three relevant knowledge entries. Treat them as investigation guidance, not proof of root cause.
5. List missing scope information explicitly. Continue when a safe, bounded Kubernetes query can resolve it; otherwise mark it for escalation.

Produce a compact scope object and a list of planned read-only checks for downstream stages. Do not access Jira in this stage.
