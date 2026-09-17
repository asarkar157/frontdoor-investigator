output "agent_id" {
  description = "ID of the investigator agent."
  value       = sg_agent.investigator.id
}

output "agent_name" {
  description = "Name of the investigator agent."
  value       = sg_agent.investigator.name
}

output "coordinator_agent_name" {
  description = "Jira-facing coordinator bound to assessment and clarification stages."
  value       = sg_agent.ticket_coordinator.name
}

output "workflow_id" {
  description = "ID of the Frontdoor investigation workflow."
  value       = sg_workflow.investigation.id
}

output "workflow_name" {
  description = "Name of the Frontdoor investigation workflow."
  value       = sg_workflow.investigation.name
}

output "runbook_names" {
  description = "Runbook SOPs bound to the investigation workflow."
  value = {
    assess_ticket       = sg_runbook_sop.assess_ticket.name
    scope               = sg_runbook_sop.scope.name
    kubernetes_evidence = sg_runbook_sop.kubernetes_evidence.name
    jenkins_evidence    = sg_runbook_sop.jenkins_evidence.name
    github_evidence     = sg_runbook_sop.github_evidence.name
    synthesis           = sg_runbook_sop.synthesis.name
    request_information = sg_runbook_sop.request_information.name
  }
}

output "integration_names" {
  description = "Integration names used by the workflow; Jira is attached only to the coordinator."
  value = {
    jira       = var.existing_jira_integration_name
    ubuntu_cli = var.existing_ubuntu_integration_name
    jenkins    = var.existing_jenkins_integration_name
  }
}

output "remote_runner_names" {
  description = "Remote runner used for every Kubernetes and GitHub operation."
  value       = var.remote_runner_names
}

output "github_hostname" {
  description = "GitHub API host used by the remote runner; this is not an integration."
  value       = var.github_hostname
}
