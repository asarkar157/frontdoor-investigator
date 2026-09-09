# Synthesize Frontdoor Investigation

Synthesize the scoped knowledge, Kubernetes evidence, and Jenkins evidence into the final investigation result.

1. Keep observations separate from hypotheses.
2. Rank no more than three hypotheses using direct evidence, contradictions, and missing checks.
3. Select a likely root cause only when evidence supports it; otherwise use `unknown`.
4. Assign calibrated high, medium, or low confidence.
5. Recommend one concrete next action and a read-only verification plan.
6. A Jenkins action may be proposed as an approval-required execution candidate, but it must not be executed.
7. Escalate when evidence is insufficient or the safe read boundary prevents confirmation.

Return exactly the `investigation_report` JSON object required by the investigator persona, with no surrounding prose.
