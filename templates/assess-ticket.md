# Assess Ticket Actionability

Use the coordinator's Jira v2 read tools to fetch the current input issue and paginate its comments completely. Do not post in this stage. If reading fails, return state integration_error and diagnostics_allowed false; do not assess an unreadable ticket as incomplete.

Classify incident versus service request and select relevant uploaded knowledge entries. Establish the symptom or requested outcome and a sufficiently unambiguous target. Time window, expected behavior, error evidence, and reproduction details are required only when they change the next diagnostic step. Do not require every ticket to have a namespace, Jenkins build, or reproduction recipe.

Examples of issue-specific facts to resolve, not mandatory questionnaires:

- Pod or deployment incident: service/workload, environment or cluster/namespace, failure time with timezone; gather logs/events yourself once scoped.
- Build/deploy failure: job/build URL or number, target environment, failing stage or release version when not discoverable from Jenkins.
- Source/release correlation: repository OWNER/REPO and commit or PR reference when relevant; these may be discoverable through remote-runner GitHub reads and must not be required for every ticket.
- Network failure: source environment, destination host/service and port, observed error and failure time.
- Access/onboarding request: target application/resource, requested role, affected account reference and approval reference if the KB requires it. Never request credentials.

Return a JSON object with ticket_assessment containing:

- ticket_key, issue_updated_at, ticket_summary, ticket_description, category, ticket_type.
- scope: service, environment, cluster_context, namespace, time_window, github_repository, commit_sha, pull_request_number (null for unknowns).
- state: actionable, needs_information, or integration_error.
- diagnostics_allowed: true only when a bounded read can target the intended resource without guessing; false when essential scope or Jira reads are missing.
- known_facts: facts and source references; kb_references: supporting document identifiers.
- questions: objects with field, question, why_needed, answer_example, blocking (boolean), owner (developer or operator), discoverable_via (kubernetes, jenkins, github, or none), and already_requested (boolean).
- operator_blockers: tool/access limitations; error: null or a concise error description.

Mark discoverable gaps as provisional so the investigator can resolve them. An actionable ticket can still have provisional questions. Missing optional data alone does not make the state needs_information. Record previously requested facts without sending reminders. Diagnostics must be disabled if this assessment is absent, malformed, or belongs to another ticket.
