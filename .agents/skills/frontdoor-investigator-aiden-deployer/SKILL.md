---
name: frontdoor-investigator-aiden-deployer
description: Deploy or update this repository's Frontdoor investigator agent and workflow in an existing Aiden/StackGen workspace using Terraform or OpenTofu. Use for workspace discovery, dependency resolution, safe planning, additive apply, and deployment verification.
---

# Frontdoor Investigator Aiden Deployer

Deploy this repository as a reusable Terraform module into an existing Aiden/StackGen workspace. Treat deployments as additive and preserve all tenant resources not owned by this module.

## Required user inputs

Ask only for:

- StackGen URL
- StackGen PAT token
- Workspace name

Never ask the user for a workspace UUID. From the repository root, resolve it with the bundled read-only helper:

```bash
python3 .agents/skills/frontdoor-investigator-aiden-deployer/scripts/resolve_workspace_uuid.py \
  --stackgen-url "$STACKGEN_URL" \
  --stackgen-token "$STACKGEN_TOKEN" \
  --workspace-name "$WORKSPACE_NAME"
```

Use the UUID from the single case-insensitive exact match as provider `project_id`. If the lookup is ambiguous, ask the user to select from the returned workspace names. Never guess.

## Deployment boundaries

- Do not create, replace, upload, or modify the workspace's Jira integration or knowledge-base documents. They are pre-existing and outside this module's ownership.
- Attach the existing Jira integration only to the ticket coordinator in this workflow. Verify the configured read-issue, paginated read-comments, and add-comment tools support REST API v2; never substitute v3-only tools. Only clarification comments are permitted writes.
- Do not use or create a native Kubernetes integration for this agent.
- Route every Kubernetes operation through the existing Ubuntu CLI integration attached to exactly one remote runner.
- Require `kubectl` and a kubeconfig backed by read-only Kubernetes RBAC in the runner environment.
- Do not commit credentials, generated plans, state, or provider caches.
- Do not delete or replace existing Aiden resources unless the user explicitly requests that destructive action.

## Resolve existing dependencies

Before composing a plan, inspect the target workspace and any Terraform state that already manages it. Resolve and reuse:

- At least one existing model name.
- The existing Jira integration name and exact v2-capable tools for issue reads, comment pagination, and comment creation. Verify developer replies and all prior comments are readable. Tool names alone do not prove API-version compatibility.
- The existing dangerous-operations policy ID.
- The optional data-risk/PII policy ID when attachment is requested.
- The existing Ubuntu CLI integration name that exposes the shell execution tool.
- The exact shell tool name, without a wildcard.
- Exactly one existing remote runner name; confirm it is online and can execute `kubectl` with read-only credentials.
- The optional existing Jenkins integration and exact read-only Jenkins tool names.

If a required dependency cannot be discovered, stop and report the exact missing resource. Do not silently provision a replacement or fall back to native Kubernetes access.

## Compose the deployment root

Prefer extending the Terraform root that already owns related resources in the resolved workspace. If no suitable root exists, create a dedicated deployment root outside this module directory and configure:

```hcl
terraform {
  required_providers {
    sg = {
      source  = "releases.stackgen.com/stackgen/stackgen"
      version = ">= 0.1.33, != 0.1.35, != 0.1.36, < 0.2.0"
    }
  }
}

provider "sg" {
  stackgen_url      = var.stackgen_url
  stackgen_token    = var.stackgen_token
  project_id        = var.stackgen_project_id
  adopt_on_conflict = true
}
```

Reference this repository with a pinned tag or commit in durable deployments. Pass the discovered values to the module:

```hcl
module "frontdoor_investigator" {
  source = "git::https://github.com/asarkar157/frontdoor-investigator.git?ref=<tag-or-commit>"

  model_names = local.existing_model_names
  existing_jira_integration_name = local.jira_integration_name
  jira_v2_tools = local.jira_v2_tools
  policy_ids = {
    dangerous_ops = local.dangerous_ops_policy_id
    data_risk_pii = local.data_risk_pii_policy_id
  }

  existing_ubuntu_integration_name  = local.ubuntu_cli_integration_name
  remote_shell_tool_name            = local.ubuntu_cli_execute_tool_name
  remote_runner_names               = [local.remote_runner_name]
  existing_jenkins_integration_name = local.jenkins_integration_name
  jenkins_readonly_tool_names       = local.jenkins_readonly_tool_names
}
```

Do not run `tofu apply` directly from this repository's module root without a deliberate deployment root, provider configuration, resolved workspace UUID, and reviewed variable values.

## Plan and apply

1. Run `tofu fmt`, `tofu init`, and `tofu validate` in the deployment root.
2. Create a saved plan with `tofu plan -out=tfplan`.
3. Inspect actions with:

   ```bash
   tofu show -json tfplan | jq -r '.resource_changes[] | [.address, (.change.actions | join(","))] | @tsv'
   ```

4. Abort on any delete, replacement, unrelated update, provider/project drift, Jira change, knowledge-base change, native Kubernetes integration, or unexpected integration/runner creation.
5. Apply only the reviewed saved plan with `tofu apply tfplan`.

Expected managed resources are the investigator and ticket coordinator, two daily budgets, their policy attachments, six runbook SOPs, and one six-stage investigation workflow. Keep the existing workflow/agent addresses stable during upgrades. Callers must now supply existing_jira_integration_name and jira_v2_tools.

## Verify

After apply:

- Report the resolved workspace name and UUID, Terraform root, plan actions, agent name, workflow name, runbook names, integration names, and remote runner name.
- Confirm there were no deletes or replacements.
- Confirm the agent exposes the Ubuntu CLI integration, not a native Kubernetes integration.
- Confirm exactly one remote runner is attached.
- Confirm the workflow starts with `assess-ticket`, continues through `scope-investigation`, `collect-kubernetes-evidence`, `collect-jenkins-evidence`, and `synthesize-investigation`, and ends with `request-information`. Only the first and last stages bind to the ticket coordinator.
- Run the offline mocked plan tests with `terraform test` (Terraform 1.7+). OpenTofu 1.11.5 with StackGen 0.1.41 fails initialization for this mock suite, although `tofu validate` works. For an authorized runtime test, follow tests/clarification-cases.md at the repository root. Check API v2 requests, blocked evidence-stage behavior, targeted questions, and duplicate suppression. These are agent/tool behaviors, not guarantees from Terraform validation.
- This module creates no webhook or reply-resumption rule. An external caller must invoke it again after developer replies, filter automation-authored comments, and serialize executions per ticket to reduce concurrent duplicate comments.
- Do not run a live investigation unless the user also authorizes that execution.
