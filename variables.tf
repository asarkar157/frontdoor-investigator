variable "model_names" {
  description = "Ordered model names available to the investigator agent."
  type        = list(string)

  validation {
    condition     = length(compact(var.model_names)) > 0
    error_message = "model_names must contain at least one non-empty model name."
  }
}

variable "existing_jira_integration_name" {
  description = "Existing Jira integration attached only to the ticket coordinator for reading tickets and adding clarification comments."
  type        = string

  validation {
    condition     = trimspace(var.existing_jira_integration_name) != ""
    error_message = "existing_jira_integration_name must not be empty."
  }
}

variable "jira_v2_tools" {
  description = "Exact tool names verified to use Jira REST API v2: read issue, paginate comments, and add a comment. No wildcard or v3-only tools."
  type = object({
    read_issue    = string
    read_comments = string
    add_comment   = string
  })

  validation {
    condition = alltrue([
      for name in values(var.jira_v2_tools) :
      trimspace(name) != "" && name == trimspace(name) && length(regexall("[?*]", name)) == 0
    ])
    error_message = "jira_v2_tools requires exact, non-empty tool names without surrounding whitespace or wildcards."
  }
}

variable "coordinator_daily_budget" {
  description = "Daily USD limit for the Jira ticket coordinator."
  type        = number
  default     = 10

  validation {
    condition     = var.coordinator_daily_budget > 0
    error_message = "coordinator_daily_budget must be greater than zero USD."
  }
}

variable "policy_ids" {
  description = "Existing Aiden policy IDs to attach to the investigator."
  type = object({
    dangerous_ops = string
    data_risk_pii = optional(string, "")
  })

  validation {
    condition     = trimspace(var.policy_ids.dangerous_ops) != ""
    error_message = "policy_ids.dangerous_ops must be a non-empty policy ID."
  }
}

variable "attach_data_risk_pii_policy" {
  description = "Attach the PII policy to both agents; requires a non-empty policy_ids.data_risk_pii."
  type        = bool
  default     = false
}

variable "existing_ubuntu_integration_name" {
  description = "Name of the existing Ubuntu CLI integration used to run kubectl on the attached remote runner."
  type        = string

  validation {
    condition     = trimspace(var.existing_ubuntu_integration_name) != ""
    error_message = "existing_ubuntu_integration_name must not be empty."
  }
}

variable "existing_jenkins_integration_name" {
  description = "Optional name of an existing Jenkins integration configured with read-only credentials."
  type        = string
  default     = ""
}

variable "remote_shell_tool_name" {
  description = "Exact Ubuntu CLI shell-tool name used for kubectl on the remote runner. Wildcards are rejected."
  type        = string

  validation {
    condition     = trimspace(var.remote_shell_tool_name) != "" && !strcontains(var.remote_shell_tool_name, "*")
    error_message = "remote_shell_tool_name must be a non-empty exact tool name without wildcards."
  }
}

variable "jenkins_readonly_tool_names" {
  description = "Fully qualified Jenkins read-tool names that may run without HITL approval. Wildcards are rejected."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for name in var.jenkins_readonly_tool_names : trimspace(name) != "" && !strcontains(name, "*")])
    error_message = "jenkins_readonly_tool_names must contain non-empty exact tool names without wildcards."
  }
}

variable "remote_runner_names" {
  description = "A single existing remote runner whose shell environment contains kubectl and a read-only kubeconfig."
  type        = set(string)

  validation {
    condition = (
      length(var.remote_runner_names) == 1
      && alltrue([for name in var.remote_runner_names : trimspace(name) != ""])
    )
    error_message = "remote_runner_names must contain exactly one non-empty runner name."
  }
}

variable "name_suffix" {
  description = "Optional suffix used to create a distinct agent instance."
  type        = string
  default     = ""

  validation {
    condition     = var.name_suffix == "" || can(regex("^[a-z0-9-]+$", var.name_suffix))
    error_message = "name_suffix may contain only lowercase letters, digits, and hyphens."
  }
}

variable "daily_budget" {
  description = "Daily USD execution limit assigned to the agent."
  type        = number
  default     = 20

  validation {
    condition     = var.daily_budget > 0
    error_message = "daily_budget must be greater than zero USD."
  }
}

variable "memory_enabled" {
  description = "Enable agent memory for continuity across investigations."
  type        = bool
  default     = true
}

variable "graph_enabled" {
  description = "Enable the knowledge graph for correlating ticket and infrastructure evidence."
  type        = bool
  default     = true
}
