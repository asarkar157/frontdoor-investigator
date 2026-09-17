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

resource "sg_runbook_sop" "github_evidence" {
  name    = "frontdoor-investigation-github${local.suffix}"
  approve = true
  description = trimspace(templatefile("${path.module}/templates/collect-github-evidence.md", {
    github_hostname = var.github_hostname
    shell_tool      = local.shell_tool_instruction
    runner_name     = one(var.remote_runner_names)
  }))
}

resource "sg_workflow" "investigation" {
  name        = local.workflow_name
  domain      = "incident-response"
  description = "Assess a Frontdoor ticket, investigate with read-only remote-runner kubectl and GitHub API calls plus optional Jenkins, and request specific missing developer information through Jira API v2."
  approve     = true

  metadata = {
    planner_max_tool_iterations = "40"
  }

  required_inputs = ["ticket_key"]
  optional_inputs = [
    "ticket_summary",
    "ticket_description",
    "service",
    "environment",
    "namespace",
    "time_window",
    "coordinator_context",
    "github_repository",
    "commit_sha",
    "pull_request_number",
  ]

  runbook_refs = [
    sg_runbook_sop.assess_ticket.name,
    sg_runbook_sop.scope.name,
    sg_runbook_sop.kubernetes_evidence.name,
    sg_runbook_sop.jenkins_evidence.name,
    sg_runbook_sop.github_evidence.name,
    sg_runbook_sop.synthesis.name,
    sg_runbook_sop.request_information.name,
  ]

  example_queries = [
    "Investigate Frontdoor ticket FD-123 for a crashing workload in the payments namespace.",
    "Correlate Kubernetes failures with the latest Jenkins deployment for checkout-api.",
  ]

  stages = [
    {
      stage_id    = "assess-ticket"
      description = "Read the current Jira v2 ticket and comments; assess actionable scope and identify specific information gaps."
      required    = true
    },
    {
      stage_id    = "scope-investigation"
      description = "Normalize the supplied ticket context and identify relevant workspace knowledge."
      required    = true
    },
    {
      stage_id    = "collect-kubernetes-evidence"
      description = "Collect current Kubernetes evidence using kubectl through the attached remote runner."
      required    = true
    },
    {
      stage_id    = "collect-jenkins-evidence"
      description = "Collect read-only Jenkins evidence, or explicitly record that Jenkins is unavailable."
      required    = true
    },
    {
      stage_id    = "collect-github-evidence"
      description = "Read scoped GitHub API evidence using gh api on the attached remote runner, or report not_applicable/unavailable."
      required    = true
    },
    {
      stage_id    = "synthesize-investigation"
      description = "Rank supported hypotheses and produce the structured investigation report."
      required    = true
    },
    {
      stage_id    = "request-information"
      description = "Recheck current Jira v2 comments and post only new, unanswered developer questions that block investigation. Otherwise return a no-op result."
      required    = true
    },
  ]

  stage_bindings = [
    {
      stage_id     = "assess-ticket"
      agent_ref    = sg_agent.ticket_coordinator.name
      runbook_refs = [sg_runbook_sop.assess_ticket.name]
      note         = "Produce ticket_assessment and normalized ticket context for every downstream stage; Jira v2 reads only at this stage."
    },
    {
      stage_id         = "scope-investigation"
      stage_depends_on = ["assess-ticket"]
      agent_ref        = sg_agent.investigator.name
      runbook_refs     = [sg_runbook_sop.scope.name]
      note             = "Establish scope and use the existing workspace knowledge base for diagnostic guidance."
    },
    {
      stage_id         = "collect-kubernetes-evidence"
      agent_ref        = sg_agent.investigator.name
      stage_depends_on = ["scope-investigation"]
      runbook_refs     = [sg_runbook_sop.kubernetes_evidence.name]
      note             = "Run every Kubernetes operation as a bounded read-only kubectl command through the attached remote runner; never look for a native Kubernetes integration."
    },
    {
      stage_id         = "collect-jenkins-evidence"
      agent_ref        = sg_agent.investigator.name
      stage_depends_on = ["scope-investigation"]
      runbook_refs     = [sg_runbook_sop.jenkins_evidence.name]
      note             = "Use only approved read-only Jenkins tools; return unavailable when Jenkins is not configured."
    },
    {
      stage_id         = "collect-github-evidence"
      agent_ref        = sg_agent.investigator.name
      stage_depends_on = ["scope-investigation"]
      runbook_refs     = [sg_runbook_sop.github_evidence.name]
      note             = "Use only the configured remote-runner shell tool for GitHub REST GET requests; never discover or use a GitHub integration. Respect diagnostics_allowed."
    },
    {
      stage_id         = "synthesize-investigation"
      agent_ref        = sg_agent.investigator.name
      stage_depends_on = ["collect-kubernetes-evidence", "collect-jenkins-evidence", "collect-github-evidence"]
      runbook_refs     = [sg_runbook_sop.synthesis.name]
      note             = "Return the investigation_report JSON contract defined by the investigator persona."
    },
    {
      stage_id         = "request-information"
      agent_ref        = sg_agent.ticket_coordinator.name
      stage_depends_on = ["synthesize-investigation"]
      runbook_refs     = [sg_runbook_sop.request_information.name]
      note             = "Use ticket_assessment and investigation_report; preserve the report in final output alongside clarification_result. Post at most one Jira v2 clarification comment per execution."
    },
  ]
}
