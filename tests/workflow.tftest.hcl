mock_provider "sg" {
  alias = "offline"
}

variables {
  model_names                      = ["test-model"]
  policy_ids                       = { dangerous_ops = "test-dangerous-policy" }
  existing_ubuntu_integration_name = "test-ubuntu"
  remote_shell_tool_name           = "test-ubuntu_execute_command"
  remote_runner_names              = ["test-runner"]
  existing_jira_integration_name   = "test-jira"
  jira_v2_tools = {
    read_issue    = "test-jira_read_issue"
    read_comments = "test-jira_read_comments"
    add_comment   = "test-jira_add_comment"
  }
}

run "isolated_permissions_and_stage_handoff" {
  command   = plan
  providers = { sg = sg.offline }

  assert {
    condition = (
      toset(sg_agent.ticket_coordinator.integrations) == toset(["test-jira"])
      && toset(sg_agent.investigator.integrations) == toset(["test-ubuntu"])
      && toset(sg_agent.investigator.remote_runners) == toset(["test-runner"])
      && !contains(sg_agent.investigator.hitl.always_allowed, "test-jira_add_comment")
    )
    error_message = "Jira writes must remain isolated from the infrastructure investigator."
  }

  assert {
    condition = (
      length(sg_workflow.investigation.stages) == 7
      && length(sg_workflow.investigation.stage_bindings) == 7
      && alltrue([for binding in sg_workflow.investigation.stage_bindings :
        binding.agent_ref == (contains(["assess-ticket", "request-information"], binding.stage_id)
        ? sg_agent.ticket_coordinator.name : sg_agent.investigator.name)
      ])
      && toset(one([for binding in sg_workflow.investigation.stage_bindings : binding
      if binding.stage_id == "scope-investigation"]).stage_depends_on) == toset(["assess-ticket"])
      && toset(one([for binding in sg_workflow.investigation.stage_bindings : binding
      if binding.stage_id == "request-information"]).stage_depends_on) == toset(["synthesize-investigation"])
      && toset(one([for binding in sg_workflow.investigation.stage_bindings : binding
        if binding.stage_id == "synthesize-investigation"]).stage_depends_on) == toset([
        "collect-kubernetes-evidence", "collect-jenkins-evidence", "collect-github-evidence"
      ])
    )
    error_message = "Assessment must precede investigation and clarification must follow synthesis on the Jira-only agent."
  }

  assert {
    condition     = toset(sg_workflow.investigation.required_inputs) == toset(["ticket_key"])
    error_message = "A sparse ticket must be invocable using its key so Jira can supply the current content."
  }
}

run "optional_jenkins_and_pii" {
  command   = plan
  providers = { sg = sg.offline }
  variables {
    existing_jenkins_integration_name = "test-jenkins"
    attach_data_risk_pii_policy       = true
    policy_ids = {
      dangerous_ops = "test-dangerous-policy"
      data_risk_pii = "test-pii-policy"
    }
  }

  assert {
    condition = (
      toset(sg_agent.investigator.integrations) == toset(["test-ubuntu", "test-jenkins"])
      && !contains(sg_agent.ticket_coordinator.integrations, "test-jenkins")
      && sg_agent_policy_attachment.data_risk_pii[0].policy_id == "test-pii-policy"
      && sg_agent_policy_attachment.coordinator_data_risk_pii[0].policy_id == "test-pii-policy"
    )
    error_message = "Jenkins is investigator-only and enabled PII protection must attach to both agents."
  }
}

run "github_enterprise_uses_existing_runner" {
  command   = plan
  providers = { sg = sg.offline }
  variables {
    github_hostname = "github.example.com"
  }

  assert {
    condition = (
      toset(sg_agent.investigator.integrations) == toset(["test-ubuntu"])
      && toset(sg_agent.investigator.remote_runners) == toset(["test-runner"])
      && strcontains(sg_runbook_sop.github_evidence.description, "gh api --hostname github.example.com --method GET")
      && strcontains(sg_runbook_sop.github_evidence.description, "test-ubuntu_execute_command")
      && strcontains(sg_runbook_sop.github_evidence.description, "test-runner")
      && strcontains(sg_agent.investigator.persona, "github.example.com")
    )
    error_message = "GitHub instructions must render the trusted host and existing runner shell without adding an integration."
  }
}

run "reject_github_url_as_hostname" {
  command   = plan
  providers = { sg = sg.offline }
  variables {
    github_hostname = "https://github.example.com/api/v3"
  }
  expect_failures = [var.github_hostname]
}

run "reject_jira_wildcard" {
  command   = plan
  providers = { sg = sg.offline }
  variables {
    jira_v2_tools = {
      read_issue    = "test-jira_read_issue"
      read_comments = "test-jira_read_comments"
      add_comment   = "test-jira_*"
    }
  }
  expect_failures = [var.jira_v2_tools]
}

run "reject_missing_jira" {
  command   = plan
  providers = { sg = sg.offline }
  variables {
    existing_jira_integration_name = ""
  }
  expect_failures = [var.existing_jira_integration_name]
}
