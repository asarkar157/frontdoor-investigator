output "agent_id" {
  description = "ID of the investigator agent."
  value       = sg_agent.investigator.id
}

output "agent_name" {
  description = "Name of the investigator agent."
  value       = sg_agent.investigator.name
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
    scope               = sg_runbook_sop.scope.name
    kubernetes_evidence = sg_runbook_sop.kubernetes_evidence.name
    jenkins_evidence    = sg_runbook_sop.jenkins_evidence.name
    synthesis           = sg_runbook_sop.synthesis.name
  }
}

output "integration_names" {
  description = "Integration names exposed to the investigator agent."
  value = {
    ubuntu_cli = var.existing_ubuntu_integration_name
    jenkins    = var.existing_jenkins_integration_name
  }
}

output "remote_runner_names" {
  description = "Remote runners used for every kubectl operation."
  value       = var.remote_runner_names
}
