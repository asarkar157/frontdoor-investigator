locals {
  suffix     = var.name_suffix == "" ? "" : "-${var.name_suffix}"
  agent_name = "frontdoor-investigator${local.suffix}"

  integration_names = compact([
    trimspace(var.existing_kubernetes_integration_name),
    trimspace(var.existing_jenkins_integration_name),
  ])
}

resource "sg_agent" "investigator" {
  name        = local.agent_name
  persona     = file("${path.module}/personas/frontdoor-investigator.md")
  model_names = compact(var.model_names)

  integrations   = local.integration_names
  remote_runners = length(var.remote_runner_names) > 0 ? var.remote_runner_names : null

  knowledge = {
    memory_enabled = var.memory_enabled
    graph_enabled  = var.graph_enabled
  }

  hitl = {
    always_allowed = distinct(concat(
      ["note", "read_notes"],
      var.kubernetes_readonly_tool_names,
      var.jenkins_readonly_tool_names,
    ))
  }
}

resource "sg_agent_budget" "investigator" {
  agent_name  = sg_agent.investigator.name
  limit_usd   = var.daily_budget
  period_type = "daily"
}

resource "sg_agent_policy_attachment" "dangerous_ops" {
  agent_name = sg_agent.investigator.name
  policy_id  = var.policy_ids.dangerous_ops
  enabled    = true
}

resource "sg_agent_policy_attachment" "data_risk_pii" {
  count = var.attach_data_risk_pii_policy && trimspace(var.policy_ids.data_risk_pii) != "" ? 1 : 0

  agent_name = sg_agent.investigator.name
  policy_id  = var.policy_ids.data_risk_pii
  enabled    = true
}
