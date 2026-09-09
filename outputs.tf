output "agent_id" {
  description = "ID of the investigator agent."
  value       = sg_agent.investigator.id
}

output "agent_name" {
  description = "Name of the investigator agent."
  value       = sg_agent.investigator.name
}

output "integration_names" {
  description = "Integration names exposed to the investigator agent."
  value = {
    kubernetes = var.existing_kubernetes_integration_name
    jenkins    = var.existing_jenkins_integration_name
  }
}
