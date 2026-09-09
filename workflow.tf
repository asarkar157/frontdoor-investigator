locals {
  workflow_name = "frontdoor-investigation${local.suffix}"

  sop_scope_name      = "frontdoor-investigation-scope${local.suffix}"
  sop_kubernetes_name = "frontdoor-investigation-kubernetes${local.suffix}"
  sop_jenkins_name    = "frontdoor-investigation-jenkins${local.suffix}"
  sop_synthesis_name  = "frontdoor-investigation-synthesis${local.suffix}"
}

resource "sg_runbook_sop" "scope" {
  name        = local.sop_scope_name
  approve     = true
  description = trimspace(file("${path.module}/templates/scope-investigation.md"))
}

resource "sg_runbook_sop" "kubernetes_evidence" {
  name        = local.sop_kubernetes_name
  approve     = true
  description = trimspace(file("${path.module}/templates/collect-kubernetes-evidence.md"))
}

resource "sg_runbook_sop" "jenkins_evidence" {
  name        = local.sop_jenkins_name
  approve     = true
  description = trimspace(file("${path.module}/templates/collect-jenkins-evidence.md"))
}

resource "sg_runbook_sop" "synthesis" {
  name        = local.sop_synthesis_name
  approve     = true
  description = trimspace(file("${path.module}/templates/synthesize-investigation.md"))
}

resource "sg_workflow" "investigation" {
  name        = local.workflow_name
  domain      = "incident-response"
  description = "Read-only investigation of a normalized Frontdoor ticket using workspace knowledge, Kubernetes evidence, and optional Jenkins evidence."
  approve     = true

  metadata = {
    planner_max_tool_iterations = "40"
  }

  required_inputs = ["ticket_key", "ticket_summary"]
  optional_inputs = [
    "ticket_description",
    "service",
    "environment",
    "namespace",
    "time_window",
    "coordinator_context",
  ]

  runbook_refs = [
    sg_runbook_sop.scope.name,
    sg_runbook_sop.kubernetes_evidence.name,
    sg_runbook_sop.jenkins_evidence.name,
    sg_runbook_sop.synthesis.name,
  ]

  example_queries = [
    "Investigate Frontdoor ticket FD-123 for a crashing workload in the payments namespace.",
    "Correlate Kubernetes failures with the latest Jenkins deployment for checkout-api.",
  ]

  stages = [
    {
      stage_id    = "scope-investigation"
      description = "Normalize the supplied ticket context and identify relevant workspace knowledge."
      required    = true
    },
    {
      stage_id    = "collect-kubernetes-evidence"
      description = "Collect current read-only Kubernetes evidence for the scoped incident."
      required    = true
    },
    {
      stage_id    = "collect-jenkins-evidence"
      description = "Collect read-only Jenkins evidence, or explicitly record that Jenkins is unavailable."
      required    = true
    },
    {
      stage_id    = "synthesize-investigation"
      description = "Rank supported hypotheses and produce the structured investigation report."
      required    = true
    },
  ]

  stage_bindings = [
    {
      stage_id     = "scope-investigation"
      agent_ref    = sg_agent.investigator.name
      runbook_refs = [sg_runbook_sop.scope.name]
      note         = "Establish scope and use the existing workspace knowledge base for diagnostic guidance."
    },
    {
      stage_id         = "collect-kubernetes-evidence"
      agent_ref        = sg_agent.investigator.name
      stage_depends_on = ["scope-investigation"]
      runbook_refs     = [sg_runbook_sop.kubernetes_evidence.name]
      note             = "Use only approved read-only Kubernetes tools."
    },
    {
      stage_id         = "collect-jenkins-evidence"
      agent_ref        = sg_agent.investigator.name
      stage_depends_on = ["scope-investigation"]
      runbook_refs     = [sg_runbook_sop.jenkins_evidence.name]
      note             = "Use only approved read-only Jenkins tools; return unavailable when Jenkins is not configured."
    },
    {
      stage_id         = "synthesize-investigation"
      agent_ref        = sg_agent.investigator.name
      stage_depends_on = ["collect-kubernetes-evidence", "collect-jenkins-evidence"]
      runbook_refs     = [sg_runbook_sop.synthesis.name]
      note             = "Return the investigation_report JSON contract defined by the investigator persona."
    },
  ]
}
