variable "region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name, used for FinOps tagging"
  type        = string
  default     = "portfolio"
}

variable "cost_center" {
  description = "Cost center tag for FinOps governance"
  type        = string
  default     = "personal-portfolio"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "multicloud-gitops-cluster"
}

variable "node_instance_type" {
  description = "EC2 instance type for the EKS managed node group (kept small/cheap intentionally)"
  type        = string
  default     = "t3.small"
}
