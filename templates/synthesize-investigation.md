# Synthesize Frontdoor Investigation

Synthesize the scoped knowledge, Kubernetes evidence, and Jenkins evidence into the final investigation result.

1. Keep observations separate from hypotheses.
2. Rank no more than three hypotheses using direct evidence, contradictions, and missing checks.
3. Select a likely root cause only when evidence supports it; otherwise use `unknown`.
4. Assign calibrated high, medium, or low confidence.
5. Recommend one concrete next action and a read-only verification plan.
6. A Jenkins action may be proposed as an approval-required execution candidate, but it must not be executed.
7. Escalate when evidence is insufficient or the safe read boundary prevents confirmation.
8. Reconcile assessment questions with gathered evidence. Remove answered and nonblocking questions. Return unresolved developer asks in clarification_questions with field, question, why_needed, answer_example, blocking, owner, discoverable_via, and already_requested. Do not ask for routine logs that were already gathered.
9. For blocked diagnostics due to missing developer scope, return needs_information and the grounded questions without fabricating observations. For invalid assessment or tool/access problems, return escalate and operator_blockers. The final coordinator stage will decide whether a new Jira comment is needed after reading current replies.

Return exactly the `investigation_report` JSON object required by the investigator persona, with no surrounding prose.
