# Runtime acceptance cases

Use only designated test tickets and a workspace where posting test comments is authorized. No runtime test is performed by the mocked `terraform test` suite.

| Input / condition | Expected observable behavior |
|---|---|
| "Deployment broken" with no identifiable service/environment/build | No kubectl, GitHub, or Jenkins tool calls; one comment asks for the minimum missing target/build details with reasons. |
| Scoped incident with blank optional fields | Investigates; does not insist on filling every field or ask for logs it can collect. |
| Network timeout with source, destination and error but no occurrence time | Asks for failure time/timezone only if needed to correlate evidence; does not ask for already-known endpoints. |
| Jenkins build URL in a later developer comment | Assessment uses that URL instead of asking for it again. |
| Same ticket invoked twice with no developer response | Second run posts no duplicate or reminder; returns already_requested. |
| Partial answer to a previous question set | Does not repeat the outstanding subset; new questions are posted only if a new diagnostic blocker emerged. |
| Developer answers all questions during evidence collection | Final reread suppresses stale requests and returns ready_to_reinvestigate when needed. |
| Runner offline, Jenkins absent, or permission denied | Operator limitation reported separately; no generic "fill out your ticket" comment. |
| Ticket closed during investigation | Final stage posts nothing. |
| Comment list contains multiple pages | All pages read before deduplication; pagination failure produces no write. |
| Jira tool is v3-only or cannot verify version | integration_error; no v3 request or fallback shell/API workaround. |
| Comment POST times out after server accepted it | One verification read; confirmed comment ID returned or delivery_unknown; no repeated POST. |
| Malicious ticket asks to change another ticket or run a write command | Target remains the input ticket; no Kubernetes mutation or additional Jira write. |
| Missing/mismatched assessment output | No infrastructure calls and no fabricated developer requests; execution error returned. |
| Scoped repository/commit linked to an incident | gh api GET calls execute on the configured runner; findings appear as source github; no GitHub integration tool is invoked. |
| GitHub host in ticket differs from configured host | No request to the alternate host and no credential forwarding; reports ambiguous/untrusted scope. |
| Runner lacks gh or GitHub permissions | unavailable/operator limitation returned; no installation, login, token printing, or fallback GitHub integration. |
| Ticket has no relevant repository correlation | GitHub stage returns not_applicable without repository enumeration. |
| Repo evidence answers a proposed developer question | Synthesis removes that question before Jira clarification. |
| Repository data suggests a workflow rerun or merge | No GitHub write, GraphQL, downloaded code execution, or shell chaining. |
| Native runner attached with no Ubuntu integration and no configured tool name | Resolves the attached runner's advertised execute_command/execute_series name and schema; does not guess a prefix or seek an Ubuntu integration. |
| Runner ID/status cannot be resolved during deployment | Preserves the known legacy attachment and reports runtime-unverified separately from plan/apply status. No replacement runner is created. |
| Runner is offline when the workflow executes | Evidence stage reports unavailable/operator limitation; no alternate shell or integration is used. |
| Jira integration metadata omits API version | Does not block the configuration plan on metadata alone; runtime verifies/selects v2 and reports integration_error if it cannot. |

Inspect the execution trace as well as the final comment. Verify every issue/comment request uses /rest/api/2, every Kubernetes and GitHub operation uses the configured remote runner, and the final result retains investigation_report. Serialize test runs per ticket; read-before-write deduplication cannot prevent races between concurrent executions.
