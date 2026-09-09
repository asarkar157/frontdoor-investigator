variable "model_names" {
  description = "Ordered model names available to the investigator agent."
  type        = list(string)

  validation {
    condition     = length(compact(var.model_names)) > 0
    error_message = "model_names must contain at least one non-empty model name."
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
  description = "Attach policy_ids.data_risk_pii when a non-empty ID is supplied."
  type        = bool
  default     = false
}

variable "existing_kubernetes_integration_name" {
  description = "Name of an existing Kubernetes integration configured with read-only credentials."
  type        = string

  validation {
    condition     = trimspace(var.existing_kubernetes_integration_name) != ""
    error_message = "existing_kubernetes_integration_name must not be empty."
  }
}

variable "existing_jenkins_integration_name" {
  description = "Optional name of an existing Jenkins integration configured with read-only credentials."
  type        = string
  default     = ""
}

variable "kubernetes_readonly_tool_names" {
  description = "Fully qualified Kubernetes read-tool names that may run without HITL approval. Wildcards are rejected."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for name in var.kubernetes_readonly_tool_names : trimspace(name) != "" && !strcontains(name, "*")])
    error_message = "kubernetes_readonly_tool_names must contain non-empty exact tool names without wildcards."
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
  description = "Existing remote runners that can reach the private integrations."
  type        = set(string)
  default     = []
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
