# Frontdoor Investigator Agent

This module creates one Frontdoor investigation workflow with two agents. The ticket coordinator reads Jira and posts an outcome comment for every completed investigation, including successful findings, suggested remediation, and specific missing-information requests when needed. The investigator uses the remote runner for Kubernetes (`kubectl`) and GitHub REST API reads (`gh api`), and optionally reads Jenkins through its integration. No GitHub integration is created or attached.

The Kubernetes, GitHub, and Jenkins identities must be read-only. The Jira identity needs permission to read the issue and comments and add comments. Personas and policies supplement integration permissions; they do not enforce endpoint selection or make a general-purpose tool read-only.

## Deployed resources

- One `frontdoor-investigator` agent and daily budget (default $20).
- One `frontdoor-ticket-coordinator` agent and daily budget (default $10).
- Dangerous-operations and optional PII policy attachments for both agents.
- Seven runbook SOPs and one `frontdoor-investigation` workflow.

The workflow requires only `ticket_key`; it reads the current summary, description, and comments from Jira. It is callable manually or by another system. This module does not register a webhook or Jira Automation rule.

| Stage | Agent | Result |
|---|---|---|
| assess-ticket | Ticket coordinator | Current ticket context, actionability, provisional questions |
| scope-investigation | Investigator | Safe diagnostic scope |
| collect-kubernetes-evidence | Investigator | kubectl evidence or blocked result |
| collect-jenkins-evidence | Investigator | Jenkins evidence, unavailable, or blocked result |
| collect-github-evidence | Investigator | Remote-runner GitHub API evidence, not_applicable, unavailable, or blocked result |
| synthesize-investigation | Investigator | Diagnosis, unresolved questions, operator limitations |
| request-information | Ticket coordinator | One outcome comment, confirmed same-run duplicate, or delivery error |

Evidence stages depend on scoping; synthesis waits for all three. All stages execute, but the SOPs instruct evidence stages to make no tool calls when `diagnostics_allowed` is false. This is agent behavior, not a deterministic Terraform condition or a runtime authorization gate.

## Final Jira update

The assessment checks whether the next diagnostic step is possible, not whether every form field is filled in. It uses issue-specific KB guidance and current comments. The investigator attempts to resolve discoverable gaps before asking the developer. Missing integrations, permission errors, or an offline runner are reported separately as operator limitations.

The final stage always prepares an outcome comment, not just clarification requests. Successful investigations post the scope, diagnosis/confidence, key evidence references, suggested remediation with owner/approval requirements, and verification steps. The comment explicitly states that no remediation was executed. Inconclusive investigations post known findings and limitations; operator blockers are not blamed on missing developer context. Closed tickets receive an informational summary without requests for action or status changes.

When developer input is needed, the same comment includes up to five new blocking questions with reasons and answer examples. Already-answered or previously requested questions are not repeated; a waiting-status update references the earlier clarification instead. New replies that invalidate findings produce a status update explaining that reinvestigation is needed, not a stale recommendation.

Comments carry `[frontdoor-investigation:v1]`. Supply optional workflow input `execution_id` (1-128 ASCII letters, digits, dots, underscores, or hyphens), reused for retries but unique for each distinct investigation. The coordinator otherwise uses a stable platform execution ID if exposed. A confirmed automation comment with the same execution marker suppresses a retry, but similar findings from another run do not suppress a new update. Without a stable ID, cross-invocation deduplication is not guaranteed. Serialize executions per ticket: read-before-write checks are not atomic. On an uncertain POST result the agent checks for delivery and never blindly retries.

Replies are considered on the next invocation; this module does not automatically resume after a reply. Filter automation-authored comments to avoid loops. Final output preserves `investigation_report` alongside the legacy `clarification_result` key, now with delivery status `posted`, `already_posted`, `delivery_unknown`, or `integration_error`, plus `comment_body`, `comment_type`, `execution_id`, and a `ready_to_reinvestigate` boolean. Callers consuming the old no-op statuses must update. Jira read/write failures, incompatible tools, invalid upstream output, or workflow termination before the final stage can prevent posting; this is an agent instruction, not guaranteed delivery or a platform failure handler.

The seven stage IDs, two agents, SOP resource names, and Terraform addresses remain unchanged. The legacy `request-information` stage now handles all final outcome comments.

## Usage

```hcl
module "frontdoor_investigator" {
  source = "git::https://github.com/asarkar157/frontdoor-investigator.git?ref=<release-tag>"

  model_names = module.foundation.model_names
  policy_ids  = module.policies.policy_ids

  existing_jira_integration_name = "existing-frontdoor-jira"
  jira_v2_tools = {
    read_issue    = "existing-frontdoor-jira_get_issue"
    read_comments = "existing-frontdoor-jira_get_comments"
    add_comment   = "existing-frontdoor-jira_add_comment"
  }

  existing_jenkins_integration_name = "production-jenkins-readonly"
  remote_runner_names               = ["celtic-k8s-runner"] # Reuse the existing attachment.

  # Omit remote_shell_tool_name to discover the runner's native shell at runtime.
  github_hostname        = "github.com" # Set the trusted Enterprise hostname when applicable.

  jenkins_readonly_tool_names = [
    "production-jenkins-readonly_get_build",
    "production-jenkins-readonly_get_build_log",
  ]

  attach_data_risk_pii_policy = true
}
```

Use the actual Jira and Jenkins tool names; the names above illustrate the expected form. For Kubernetes and GitHub, the attached runner provides native execute_command/execute_series tools. No Ubuntu CLI integration is required. Preserve the existing runner name/identifier; runtime tool names may be qualified by a different runner ID and must not be guessed from its display name.

`remote_shell_tool_name` is optional. When omitted, the agent discovers the attached runner's shell capability and input schema at runtime; no unknown tool or wildcard is auto-approved. Existing runtime approval policies still apply. Set an exact tool name only when it is known. `existing_ubuntu_integration_name` is retained as an optional compatibility input for an already-working legacy shell route; it is not a required dependency.

The three Jira tools must support v2 issue reads, paginated comment reads, and comment creation at runtime. The coordinator persona renders their configured names and requires `/rest/api/2`, with a string `body` for comments. See the [Jira v2 comment API example](https://developer.atlassian.com/server/jira/platform/jira-rest-api-example-add-comment-8946422/). Missing API-version metadata is not evidence of incompatibility and does not prevent deploying this configuration. Record the capability as unverified until tool schemas/documentation or an authorized v2 read establish support. Known v3-only tools remain incompatible. At runtime the agent must return `integration_error` if it cannot select/verify v2, rather than fall back to v3.

At runtime the remote runner must provide `kubectl` and a kubeconfig backed by a read-only Kubernetes identity. The shell tool is general-purpose, not inherently read-only. Read-only credentials and the command restrictions provide the boundary; an exact shell tool allow-list alone does not restrict its command arguments.

## GitHub through the runner

The attached runner's shell handles every GitHub request using `gh api --hostname <configured-host> --method GET`. `github_hostname` defaults to `github.com`; set it to the trusted GitHub Enterprise hostname for your workspace. Ticket text cannot override this host. Reads are scoped to the ticket's repository, commits, PRs, releases, and check/run metadata. The workflow does not merge, comment on, or modify GitHub objects.

Install `gh` and provide host-appropriate, repository-scoped read-only authentication in the actual runner shell environment. GitHub CLI supports `GH_TOKEN`/`GITHUB_TOKEN` for github.com and `GH_ENTERPRISE_TOKEN`/`GITHUB_ENTERPRISE_TOKEN` for Enterprise Server; see the [CLI environment reference](https://cli.github.com/manual/gh_help_environment). Credentials are consumed implicitly and must not be put in Terraform variables, command arguments, or output. Existing host-scoped CLI authentication is also supported. The configured shell tool must execute on the named runner; the Terraform module does not install gh, inject credentials, or verify routing itself.

Optional workflow inputs `github_repository` (OWNER/REPO), `commit_sha`, and `pull_request_number` help scope correlation. The agent also uses current Jira context and verified KB mappings. Unrelated tickets return `not_applicable`; missing gh, authentication, connectivity, or permissions produce an operator limitation and allow synthesis to continue. The agent must never fall back to a GitHub integration. Calls use explicit GET and bounded pagination following the [gh api interface](https://cli.github.com/manual/gh_api).

Omit `existing_jenkins_integration_name` when Jenkins is unavailable. In that configuration, the investigator still produces a useful Kubernetes-backed diagnosis but returns Jenkins-specific evidence or execution recommendations as missing information.

The calling root module must configure the StackGen provider with the target project UUID and existing tenant credentials. This module creates no integrations and does not adopt or modify existing integration resources.

## Existing workspace resources

The workspace must already contain the Frontdoor knowledge-base documents and Jira integration. Only the new ticket coordinator attaches Jira. Knowledge memory and graph settings remain enabled by default; verify that the uploaded documents are accessible to both agents. This module does not upload or replace them.

## Upgrade and verification

Existing callers must now supply `existing_jira_integration_name` and `jira_v2_tools`. Agent and workflow resource addresses remain stable. Enabling PII requires a non-empty PII policy ID for both agents.

For an existing agent attached to `celtic-k8s-runner`, preserve that attachment in the same Terraform state root. Failure to resolve its ID/status through a separate runners API does not prove it is missing, and this module performs no runner data-source lookup. A plan/apply can update the configuration while runtime readiness remains unverified. If the runner is offline or has no callable shell at execution time, the workflow reports an operator limitation. No replacement runner or Ubuntu integration should be created to work around missing discovery metadata.

Run `tofu fmt -check -recursive`, `tofu validate`, and `terraform test` (Terraform 1.7+). Tests use a mocked provider with plan-only runs and do not contact a workspace. OpenTofu 1.11.5 with StackGen 0.1.41 fails provider initialization in this mocked test suite; use Terraform for the tests. Runtime acceptance cases are in [tests/clarification-cases.md](tests/clarification-cases.md); they require an explicitly selected test ticket and are not covered by Terraform validation.
