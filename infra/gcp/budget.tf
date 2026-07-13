# FinOps: budget + alert thresholds so free-trial credit burn is visible and
# governed, not just discovered after the fact. Disabled by default because it
# requires Billing Account Administrator on the deploy service account; enable
# once that role is granted (see README bootstrap steps).
resource "google_billing_budget" "portfolio" {
  count = var.enable_budget_alert ? 1 : 0

  billing_account = var.billing_account_id
  display_name    = "multicloud-gitops-platform-budget"

  budget_filter {
    projects = ["projects/${var.project_id}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.budget_amount_usd)
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }

  threshold_rules {
    threshold_percent = 0.9
  }

  threshold_rules {
    threshold_percent = 1.0
  }
}
