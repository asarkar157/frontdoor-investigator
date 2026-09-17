# Request Specific Missing Information

Consume ticket_assessment and investigation_report from upstream stages. Missing or mismatched upstream output is an execution error, not a reason to invent questions or post. Preserve the investigation_report in the final output.

1. If assessment failed to read Jira, return integration_error without posting. Otherwise re-read the input issue and all comment pages through Jira API v2, even if an earlier stage already read them.
2. Consider only unresolved blocking questions owned by the developer, grounded in the assessment or investigation evidence. Remove questions answered by current issue fields, developer replies, or Kubernetes/Jenkins/GitHub findings. Exclude operator/tool limitations and information that is merely helpful.
3. If the report is diagnosed, the issue is resolved/closed, or no blocking developer questions remain, post nothing. If new answers make another investigation possible, return ready_to_reinvestigate without claiming the stale report is current.
4. Compare against prior comments semantically, not just exact text. If the same facts were already requested and remain unanswered, return already_requested. Partial replies should yield only genuinely new questions, not reminders for the unanswered subset. Use a stable field identifier in each question and include the marker [frontdoor-clarification:v1] to aid later recognition; do not rely on the marker alone.
5. Immediately before writing, re-read the issue and comments again. If the issue changed, reassess the candidate questions once. If it keeps changing or history is incomplete, return deferred/integration_error and do not post.
6. Post at most one comment with up to five highest-priority new questions, a concise description of what is known, and why the answers are needed. Use POST /rest/api/2/issue/{ticket_key}/comment with a string body. Example text:

   Aiden could not identify the failed deployment from the current ticket. To continue:
   1. [deployment.build] Which Jenkins job and build number failed? A build URL is sufficient; this identifies the failing stage and its logs.
   2. [scope.environment] Which environment was targeted (for example QA or SignOff-R2)? This identifies the workload to inspect.
   Reply in this ticket. Please redact credentials and customer data.
   [frontdoor-clarification:v1]

7. Only return posted after receiving a comment ID or confirming the exact new comment through a subsequent read. On timeout or uncertain write outcome, re-read once; if unconfirmed return delivery_unknown without retrying POST. On permission or API-version failure return integration_error, preserving the questions for operator follow-up.

Return JSON with investigation_report unchanged and clarification_result containing ticket_key, status (posted, not_needed, already_requested, ready_to_reinvestigate, deferred, delivery_unknown, or integration_error), comment_id (null unless confirmed), questions (the structured candidate questions), reason, and operator_blockers. This stage does not wait for replies or schedule another execution.
