# Collect Jenkins Evidence

Correlate the incident with CI/CD activity without changing Jenkins state.

First check the upstream scope and ticket_assessment. Unless diagnostics_allowed is explicitly true for this ticket, return jenkins_evidence_status blocked (or invalid_assessment) with no tool calls. The stage completes so synthesis and clarification can run. Do not guess a job when its service/environment mapping is ambiguous.

1. If no Jenkins integration is available, return `jenkins_evidence_status` as `unavailable` and explain that no Jenkins correlation was performed. The stage still completes successfully.
2. When Jenkins is available, inspect only job metadata, build metadata, parameters, queue state, history, and redacted console logs.
3. Identify deployments or failed builds relevant to the service, environment, and incident time window.
4. Record job names, build numbers, timestamps, outcomes, and concise redacted findings.
5. Never start, retry, replay, rebuild, stop, configure, enable, disable, or delete a job or build.

Return `jenkins_evidence_status` as `collected`, `unavailable`, `insufficient`, `blocked`, or `invalid_assessment`, followed by observations and evidence references. Missing Jenkins or access failures are operator limitations. A precise developer-supplied build link or redacted failing-stage excerpt may still be requested when it is essential and cannot be obtained from available evidence.
