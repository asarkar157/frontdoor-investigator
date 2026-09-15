# Frontdoor Investigator Agent

This module creates the read-only investigator and its executable investigation workflow. It inspects Kubernetes exclusively by running kubectl through an Ubuntu CLI integration on an attached remote runner, and it can optionally inspect Jenkins. Jira is deliberately excluded because ticket intake and updates belong to the coordinator stage.

The integration identities supplied to this module must be read-only. The persona and dangerous-operations policy provide defense in depth, but they do not replace least-privilege credentials at the integration layer.

## Deployed resources

- One `frontdoor-investigator` agent and daily budget.
- Dangerous-operations policy attachment and optional PII policy attachment.
- Four investigation runbook SOPs for scoping, remote-runner kubectl evidence, Jenkins evidence, and synthesis.
- One `frontdoor-investigation` workflow with all four stages bound to the investigator agent.

The workflow requires `ticket_key` and `ticket_summary`. It is callable by an upstream coordinator or manually; it does not register a Jira trigger or update Jira directly.

## Usage

```hcl
module "frontdoor_investigator" {
  source = "git::https://github.com/asarkar157/frontdoor-investigator.git?ref=<release-tag>"

  model_names = module.foundation.model_names
  policy_ids  = module.policies.policy_ids

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

The remote runner must provide `kubectl` and a kubeconfig backed by a read-only Kubernetes identity. Credential-level RBAC is mandatory because auto-approving the shell tool permits unattended investigation; persona and policy controls are additional safeguards, not a substitute for read-only credentials.

Omit `existing_jenkins_integration_name` when Jenkins is unavailable. In that configuration, the investigator still produces a useful Kubernetes-backed diagnosis but returns Jenkins-specific evidence or execution recommendations as missing information.

The calling root module must configure the StackGen provider with the target project UUID and existing tenant credentials. This module creates no integrations and does not adopt or modify existing integration resources.

## Existing workspace resources

The phase-one workflow is expected to run in a workspace where the Frontdoor knowledge-base documents and Jira integration already exist. This investigator does not attach Jira because ticket intake and status publishing belong to the coordinator agent. Knowledge access is enabled through the agent's workspace memory and graph settings; the module does not upload or replace knowledge-base documents.
