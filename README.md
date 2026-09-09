# Frontdoor Investigator Agent

This module creates the read-only investigator used by the phase-one Frontdoor workflow. It can inspect Kubernetes and, optionally, Jenkins. Jira is deliberately excluded because ticket intake and updates belong to the coordinator stage.

The integration identities supplied to this module must be read-only. The persona and dangerous-operations policy provide defense in depth, but they do not replace least-privilege credentials at the integration layer.

## Usage

```hcl
module "frontdoor_investigator" {
  source = "git::https://github.com/asarkar157/frontdoor-investigator.git?ref=<release-tag>"

  model_names = module.foundation.model_names
  policy_ids  = module.policies.policy_ids

  existing_kubernetes_integration_name = "production-kubernetes-readonly"
  existing_jenkins_integration_name    = "production-jenkins-readonly"
  remote_runner_names                  = ["private-network-runner"]

  kubernetes_readonly_tool_names = [
    "production-kubernetes-readonly_get_pods",
    "production-kubernetes-readonly_describe_pod",
    "production-kubernetes-readonly_get_pod_logs",
    "production-kubernetes-readonly_list_events",
  ]

  jenkins_readonly_tool_names = [
    "production-jenkins-readonly_get_build",
    "production-jenkins-readonly_get_build_log",
  ]

  attach_data_risk_pii_policy = true
}
```

Use the exact tool names exposed by the tenant integrations; the names above illustrate the expected form. Keep the allow-lists limited to verified read operations. Wildcards are rejected so a future write tool cannot become auto-approved accidentally.

Omit `existing_jenkins_integration_name` when Jenkins is unavailable. In that configuration, the investigator still produces a useful Kubernetes-backed diagnosis but returns Jenkins-specific evidence or execution recommendations as missing information.

The calling root module must configure the StackGen provider with the target project UUID and existing tenant credentials. This module creates no integrations and does not adopt or modify existing integration resources.

## Existing workspace resources

The phase-one workflow is expected to run in a workspace where the Frontdoor knowledge-base documents and Jira integration already exist. This investigator does not attach Jira because ticket intake and status publishing belong to the coordinator agent. Knowledge access is enabled through the agent's workspace memory and graph settings; the module does not upload or replace knowledge-base documents.
