variable "model_names" {
  description = "Ordered model names available to the investigator agent."
  type        = list(string)

  validation {
    condition     = length(compact(var.model_names)) > 0
    error_message = "model_names must contain at least one non-empty model name."
  }
}

variable "existing_jira_integration_name" {
  description = "Existing Jira integration attached only to the ticket coordinator for reading tickets and posting investigation outcome comments."
  type        = string

  validation {
    condition     = trimspace(var.existing_jira_integration_name) != ""
    error_message = "existing_jira_integration_name must not be empty."
  }
}

variable "jira_v2_tools" {
  description = "Actual Jira tool names for issue reads, comment pagination, and comment creation. Runtime must select/verify API v2; missing version metadata alone does not prevent configuration deployment."
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
  description = "Optional legacy shell integration, only for deployments that already route it to the runner. Native runner shell tools require no Ubuntu integration."
  type        = string
  default     = ""
}

variable "existing_jenkins_integration_name" {
  description = "Optional name of an existing Jenkins integration configured with read-only credentials."
  type        = string
  default     = ""
}

variable "remote_shell_tool_name" {
  description = "Optional exact runner shell tool name, if known. When empty, discover execute_command/execute_series on the attached runner at runtime; no inferred tool is auto-approved."
  type        = string
  default     = ""

  validation {
    condition     = var.remote_shell_tool_name == trimspace(var.remote_shell_tool_name) && length(regexall("[?*]", var.remote_shell_tool_name)) == 0
    error_message = "remote_shell_tool_name must be empty or an exact tool name without whitespace padding or wildcards."
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
  description = "One attached runner name or identifier, preserved from the existing agent/state when available. Runtime requires kubectl, gh, and their credentials; no runners API lookup is required to plan."
  type        = set(string)

  validation {
    condition = (
      length(var.remote_runner_names) == 1
      && alltrue([for name in var.remote_runner_names : trimspace(name) != ""])
    )
    error_message = "remote_runner_names must contain exactly one non-empty runner name."
  }
}

variable "github_hostname" {
  description = "Trusted GitHub hostname for remote-runner gh api calls; use the GitHub Enterprise hostname when applicable. No scheme, path, or credentials."
  type        = string
  default     = "github.com"

  validation {
    condition = (
      length(var.github_hostname) <= 253
      && alltrue([for label in split(".", var.github_hostname) :
        can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", label))
      ])
    )
    error_message = "github_hostname must be a lowercase DNS hostname without a scheme, port, path, or credentials."
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
