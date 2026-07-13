variable "project_id" {
  description = "GCP project ID (free trial project)"
  type        = string
}

variable "region" {
  description = "Primary region for all resources"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name, used for labeling (FinOps tagging)"
  type        = string
  default     = "portfolio"
}

variable "cost_center" {
  description = "Cost center label for FinOps resource tagging/governance"
  type        = string
  default     = "personal-portfolio"
}

variable "enable_budget_alert" {
  description = "Whether to create a Cloud Billing budget + alert (requires billing account admin on the deploy SA)"
  type        = bool
  default     = false
}

variable "billing_account_id" {
  description = "Billing account ID, required only if enable_budget_alert is true"
  type        = string
  default     = ""
}

variable "budget_amount_usd" {
  description = "Monthly budget threshold in USD"
  type        = number
  default     = 25
}
