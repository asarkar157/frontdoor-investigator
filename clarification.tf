resource "sg_agent" "ticket_coordinator" {
  name = "frontdoor-ticket-coordinator${local.suffix}"
  persona = templatefile("${path.module}/personas/frontdoor-ticket-coordinator.md", {
    issue_tool    = var.jira_v2_tools.read_issue
    comments_tool = var.jira_v2_tools.read_comments
    comment_tool  = var.jira_v2_tools.add_comment
  })
  model_names  = compact(var.model_names)
  integrations = [trimspace(var.existing_jira_integration_name)]

  knowledge = {
    memory_enabled = var.memory_enabled
    graph_enabled  = var.graph_enabled
  }

  hitl = {
    always_allowed = distinct([
      var.jira_v2_tools.read_issue,
      var.jira_v2_tools.read_comments,
      var.jira_v2_tools.add_comment,
    ])
  }
}

resource "sg_agent_budget" "ticket_coordinator" {
  agent_name  = sg_agent.ticket_coordinator.name
  limit_usd   = var.coordinator_daily_budget
  period_type = "daily"
}

resource "sg_agent_policy_attachment" "coordinator_dangerous_ops" {
  agent_name = sg_agent.ticket_coordinator.name
  policy_id  = var.policy_ids.dangerous_ops
  enabled    = true
}

resource "sg_agent_policy_attachment" "coordinator_data_risk_pii" {
  count      = var.attach_data_risk_pii_policy ? 1 : 0
  agent_name = sg_agent.ticket_coordinator.name
  policy_id  = var.policy_ids.data_risk_pii
  enabled    = true

  lifecycle {
    precondition {
      condition     = trimspace(var.policy_ids.data_risk_pii) != ""
      error_message = "Enabling the PII policy requires a non-empty policy_ids.data_risk_pii."
    }
  }
}

resource "sg_runbook_sop" "assess_ticket" {
  name        = "frontdoor-assess-ticket${local.suffix}"
  approve     = true
  description = trimspace(file("${path.module}/templates/assess-ticket.md"))
}

resource "sg_runbook_sop" "request_information" {
  name        = "frontdoor-request-information${local.suffix}"
  approve     = true
  description = trimspace(file("${path.module}/templates/request-information.md"))
}
