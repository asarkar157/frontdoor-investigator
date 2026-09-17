# Frontdoor Investigator Agent

This module creates one Frontdoor investigation workflow with two agents. The ticket coordinator reads Jira and requests specific missing developer information. The investigator inspects Kubernetes exclusively through remote-runner kubectl and optionally reads Jenkins.

The Kubernetes and Jenkins identities must be read-only. The Jira identity needs permission to read the issue and comments and add comments. Personas and policies supplement integration permissions; they do not enforce endpoint selection or make a general-purpose tool read-only.

## Deployed resources

- One `frontdoor-investigator` agent and daily budget (default $20).
- One `frontdoor-ticket-coordinator` agent and daily budget (default $10).
- Dangerous-operations and optional PII policy attachments for both agents.
- Six runbook SOPs and one `frontdoor-investigation` workflow.

The workflow requires only `ticket_key`; it reads the current summary, description, and comments from Jira. It is callable manually or by another system. This module does not register a webhook or Jira Automation rule.

| Stage | Agent | Result |
|---|---|---|
| assess-ticket | Ticket coordinator | Current ticket context, actionability, provisional questions |
| scope-investigation | Investigator | Safe diagnostic scope |
| collect-kubernetes-evidence | Investigator | kubectl evidence or blocked result |
| collect-jenkins-evidence | Investigator | Jenkins evidence, unavailable, or blocked result |
| synthesize-investigation | Investigator | Diagnosis, unresolved questions, operator limitations |
| request-information | Ticket coordinator | One clarification comment or explicit no-op/error |

Evidence stages depend on scoping; synthesis waits for both. All stages execute, but the SOPs instruct evidence stages to make no tool calls when `diagnostics_allowed` is false. This is agent behavior, not a deterministic Terraform condition or a runtime authorization gate.

## Clarification behavior

The assessment checks whether the next diagnostic step is possible, not whether every form field is filled in. It uses issue-specific KB guidance and current comments. The investigator attempts to resolve discoverable gaps before asking the developer. Missing integrations, permission errors, or an offline runner are reported separately as operator limitations.

The final stage rechecks current comments and asks up to five concrete blocking questions, with a reason and expected answer format. Example: "Which Jenkins job and build number failed? A build URL is sufficient; it identifies the failing stage and logs." It does not request information already answered or repeat outstanding asks. A completed diagnosis does not generate a clarification comment.

Comments carry `[frontdoor-clarification:v1]`. The agent checks semantic duplicates and rereads before writing. This reduces duplicates but is not an atomic exactly-once guarantee: the caller should serialize executions per ticket. After an uncertain POST result, it checks for the comment and never blindly retries.

Replies are considered on the next invocation; this module does not automatically resume after a reply. The caller can invoke it again for developer updates and should filter out comments authored by the automation account to avoid loops. Final output preserves `investigation_report` alongside `clarification_result` (posted, not_needed, already_requested, ready_to_reinvestigate, deferred, delivery_unknown, or integration_error).

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

  existing_ubuntu_integration_name  = "production-ubuntu-cli"
  existing_jenkins_integration_name = "production-jenkins-readonly"
  remote_runner_names               = ["private-network-runner"]

  remote_shell_tool_name = "production-ubuntu-cli_execute_command"

  jenkins_readonly_tool_names = [
    "production-jenkins-readonly_get_build",
    "production-jenkins-readonly_get_build_log",
  ]

  attach_data_risk_pii_policy = true
}
```

Use the exact tool names exposed by the tenant integrations; the names above illustrate the expected form. Wildcards are rejected. The Ubuntu CLI integration and remote runner are both required so the agent has one explicit Kubernetes execution path.

The three Jira tools must support v2 issue reads, paginated comment reads, and comment creation. The coordinator persona renders their configured names and requires `/rest/api/2`, with a string `body` for comments. See the [Jira v2 comment API example](https://developer.atlassian.com/server/jira/platform/jira-rest-api-example-add-comment-8946422/). Terraform cannot verify a tool's implementation from its name. If the existing tool is v3-only or cannot expose/select its version, deployment requires a compatible tool; the agent must return `integration_error` rather than fall back to v3. These exact tools are auto-approved, so validate their capabilities before deployment.

The remote runner must provide `kubectl` and a kubeconfig backed by a read-only Kubernetes identity. Credential-level RBAC is mandatory because auto-approving the shell tool permits unattended investigation; persona and policy controls are additional safeguards, not a substitute for read-only credentials.

Omit `existing_jenkins_integration_name` when Jenkins is unavailable. In that configuration, the investigator still produces a useful Kubernetes-backed diagnosis but returns Jenkins-specific evidence or execution recommendations as missing information.

The calling root module must configure the StackGen provider with the target project UUID and existing tenant credentials. This module creates no integrations and does not adopt or modify existing integration resources.

## Existing workspace resources

The workspace must already contain the Frontdoor knowledge-base documents and Jira integration. Only the new ticket coordinator attaches Jira. Knowledge memory and graph settings remain enabled by default; verify that the uploaded documents are accessible to both agents. This module does not upload or replace them.

## Upgrade and verification

Existing callers must now supply `existing_jira_integration_name` and `jira_v2_tools`. Agent and workflow resource addresses remain stable. Enabling PII requires a non-empty PII policy ID for both agents.

Run `tofu fmt -check -recursive`, `tofu validate`, and `terraform test` (Terraform 1.7+). Tests use a mocked provider with plan-only runs and do not contact a workspace. OpenTofu 1.11.5 with StackGen 0.1.41 fails provider initialization in this mocked test suite; use Terraform for the tests. Runtime acceptance cases are in [tests/clarification-cases.md](tests/clarification-cases.md); they require an explicitly selected test ticket and are not covered by Terraform validation.
