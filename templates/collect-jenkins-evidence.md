# Collect Jenkins Evidence

Correlate the incident with CI/CD activity without changing Jenkins state.

1. If no Jenkins integration is available, return `jenkins_evidence_status` as `unavailable` and explain that no Jenkins correlation was performed. The stage still completes successfully.
2. When Jenkins is available, inspect only job metadata, build metadata, parameters, queue state, history, and redacted console logs.
3. Identify deployments or failed builds relevant to the service, environment, and incident time window.
4. Record job names, build numbers, timestamps, outcomes, and concise redacted findings.
5. Never start, retry, replay, rebuild, stop, configure, enable, disable, or delete a job or build.

Return `jenkins_evidence_status` as `collected`, `unavailable`, or `insufficient`, followed by observations and evidence references.
