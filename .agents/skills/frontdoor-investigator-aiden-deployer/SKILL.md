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
  --workspace-name "$WORKSPACE_NAME"
```

The helper reads STACKGEN_TOKEN from the environment. Use secure credential injection; do not echo tokens, put them in command arguments, dump integration secrets, or inspect terminal history for credentials. If a token was exposed, report the need for revocation/replacement without repeating it.

Use the UUID from the single case-insensitive exact match as provider `project_id`. If the lookup is ambiguous, ask the user to select from the returned workspace names. Never guess.

## Deployment boundaries

- Do not create, replace, upload, or modify the workspace's Jira integration or knowledge-base documents. They are pre-existing and outside this module's ownership.
- Attach the existing Jira integration only to the ticket coordinator. Configure its actual issue-read, paginated comment-read, and add-comment tool names. Require API v2 in the rendered persona and SOPs. Missing version metadata is not evidence of v3-only support and does not block planning/applying the configuration. Verify endpoint selection from tool schemas/documentation or an authorized v2 read; record unverified capability when no test is possible. Known v3-only tools are incompatible and must not be used. Only clarification comments are permitted writes.
- Do not use or create a native Kubernetes integration for this agent.
- Route every Kubernetes operation through the attached runner's own shell capability. Do not require, provision, or search indefinitely for an Ubuntu CLI integration. existing_ubuntu_integration_name is an optional compatibility input for already-working legacy shell routes.
- Require `kubectl` and a kubeconfig backed by read-only Kubernetes RBAC in the runner environment.
- Route all GitHub REST GET calls through the same remote-runner shell using gh api. Never create, attach, or fall back to a GitHub integration. Discover the trusted GitHub hostname and set github_hostname for Enterprise; never derive an authenticated destination from arbitrary ticket text.
- Do not commit credentials, generated plans, state, or provider caches.
- Do not delete or replace existing Aiden resources unless the user explicitly requests that destructive action.

## Resolve existing dependencies

Before composing a plan, inspect the target workspace and any Terraform state that already manages it. Resolve and reuse:

- At least one existing model name.
- The existing Jira integration name and actual tool names for issue reads, comment pagination, and comment creation. Treat metadata, configuration and runtime API verification as separate evidence. Do not invent tool names or claim v2 is verified from an integration label.
- The existing dangerous-operations policy ID.
- The optional data-risk/PII policy ID when attachment is requested.
- Exactly one runner name/identifier from the current agent attachment or its Terraform state. Reuse it unchanged even if a separate runners API lookup cannot resolve ID/status. Do not create a replacement runner, remove the attachment, or require importing a runner that this root does not own.
- An exact runner shell tool name if known from an execution trace or capability discovery. Otherwise omit remote_shell_tool_name; the agent resolves the attached runner's execute_command/execute_series capability at runtime. Do not infer a tool name from a display name or automatically approve wildcards. No shell integration or tool lookup is required to generate a plan.
- The runner shell must also provide gh and host-scoped read-only GitHub authentication for relevant repositories. Reuse existing credentials without printing them or adding tokens to Terraform or command arguments. If unavailable, report the limitation; the workflow records GitHub evidence as unavailable rather than using a GitHub integration. Confirm the shell tool actually executes on the attached runner.
- The optional existing Jenkins integration and exact read-only Jenkins tool names.

Distinguish configuration blockers from runtime readiness. A missing workspace identity, missing required model/policy/integration reference, invalid provider arguments, or API rejection can block deployment. An unknown runner status, undiscoverable shell tool at deployment time, unavailable CLI/credentials, or Jira metadata lacking a version cannot by itself block a valid configuration update. Report these as runtime-unverified, proceed with the authorized in-place plan/apply, and do not claim the workflow is operational until exercised. Execution must still fail clearly if no callable runner or compatible Jira tool is available.

For the ase legacy upgrade, if the existing frontdoor-investigator agent is attached to celtic-k8s-runner, preserve that exact attachment. Extend the existing frontdoor-investigator state root that owns the agent, budget, and policy attachment; add the workflow/SOPs/coordinator there. Do not require the workflow to exist already. Inspect existing Terraform addresses and use reviewed moved blocks/imports only if ownership migration is actually needed. Missing new resources are the purpose of the additive plan, not blockers.

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

  remote_runner_names               = [local.remote_runner_name]
  # Omit shell integration/tool inputs for native runner discovery.
  github_hostname                   = local.github_hostname
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

Expected managed resources are the investigator and ticket coordinator, two daily budgets, their policy attachments, seven runbook SOPs, and one seven-stage investigation workflow. Keep the existing workflow/agent addresses stable during upgrades. Callers must supply existing_jira_integration_name and jira_v2_tools. GitHub and Kubernetes use remote_runner_names; remote_shell_tool_name is optional and no GitHub or Ubuntu integration is required.

## Verify

After apply:

- Report the resolved workspace name and UUID, Terraform root, plan actions, agent name, workflow name, runbook names, integration names, and remote runner name.
- Confirm there were no deletes or replacements.
- Confirm the agent preserves the intended runner attachment and has no native Kubernetes integration. Ubuntu is optional and must not be added as a deployment prerequisite.
- Confirm exactly one remote runner is attached.
- Confirm no GitHub integration is attached, and the rendered GitHub SOP names the runner and trusted hostname, with either an explicit tool or native shell discovery instructions.
- Report runner connectivity and Jira v2 readiness as verified, unverified, or failed, separately from Terraform apply success. A successful apply does not prove runtime connectivity.
- Confirm the workflow starts with `assess-ticket`, continues through `scope-investigation`, `collect-kubernetes-evidence`, `collect-jenkins-evidence`, `collect-github-evidence`, and `synthesize-investigation`, and ends with `request-information`. Synthesis waits for all three evidence stages. Only the first and last stages bind to the ticket coordinator.
- Run the offline mocked plan tests with `terraform test` (Terraform 1.7+). OpenTofu 1.11.5 with StackGen 0.1.41 fails initialization for this mock suite, although `tofu validate` works. For an authorized runtime test, follow tests/clarification-cases.md at the repository root. Check API v2 requests, blocked evidence-stage behavior, targeted questions, and duplicate suppression. These are agent/tool behaviors, not guarantees from Terraform validation.
- This module creates no webhook or reply-resumption rule. An external caller must invoke it again after developer replies, filter automation-authored comments, and serialize executions per ticket to reduce concurrent duplicate comments.
- Do not run a live investigation unless the user also authorizes that execution.
