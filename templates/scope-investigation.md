# Scope Frontdoor Investigation

Normalize the input supplied by the upstream coordinator before using infrastructure tools.

Read ticket_assessment from assess-ticket. Use its current Jira fields in preference to stale invocation fields. Carry diagnostics_allowed, questions, and operator_blockers into the scope output. If diagnostics_allowed is false or the assessment is invalid/missing, do not query infrastructure; return bounded known scope and unresolved gaps. Do not try to bypass this decision through knowledge-base suggestions.

1. Preserve `ticket_key` and summarize the reported symptom without inventing missing facts.
2. Determine the service, environment, namespace, affected users, and incident time window from the supplied fields.
3. Search the existing workspace knowledge base for the most relevant issue patterns and diagnostic procedures.
4. Select no more than three relevant knowledge entries. Treat them as investigation guidance, not proof of root cause.
5. List missing scope information explicitly. Continue when a safe, bounded remote-runner kubectl query can resolve it; otherwise mark it for escalation.
6. Carry github_repository (OWNER/REPO), commit_sha, and pull_request_number into scoped context when supplied in the ticket, invocation, or a verified KB mapping. Determine whether GitHub correlation is relevant. Resolve conflicts using current ticket context and do not infer a repository from the deployment module's own Git remote. Any GitHub lookup must use gh api GET through the configured remote runner.

Produce a compact scope object and a list of planned read-only checks for downstream stages. Do not access Jira in this stage.
