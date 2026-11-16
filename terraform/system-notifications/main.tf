# This destination is owned by the application root; do not duplicate its input.
data "xcsh_alert_receiver" "dedicated" {
  name      = "csd-page-tamper-alert-receiver"
  namespace = "client-side-defense"

  lifecycle {
    postcondition {
      condition     = try(length(trimspace(self.email.email)) > 0, false)
      error_message = "The existing dedicated receiver must have a nonempty email destination."
    }
  }
}

resource "xcsh_alert_receiver" "system" {
  name      = "client-side-defense-receiver"
  namespace = "system"

  email {
    email = sensitive(try(data.xcsh_alert_receiver.dedicated.email.email, ""))
  }

  lifecycle {
    prevent_destroy = true
  }
}

variable "adopt_existing_policy" {
  description = "Import the pre-existing system policy. Disable only for isolated mock tests or a verified new tenant without that policy."
  type        = bool
  default     = true
  nullable    = false
}

import {
  for_each = var.adopt_existing_policy ? toset(["system/client-side-defense-policy"]) : toset([])
  to       = xcsh_alert_policy.system
  id       = each.value
}

# A recreated receiver retains its name/ID. A persistent generation value makes
# Terraform send the policy update instead of collapsing it to an identical name.
resource "terraform_data" "receiver_generation" {
  input = xcsh_alert_receiver.system.id

  # A refreshed-away receiver plans creation, which replace_triggered_by alone
  # does not cover. Its unknown ID must also force a new local generation.
  triggers_replace = xcsh_alert_receiver.system.id

  lifecycle {
    replace_triggered_by = [xcsh_alert_receiver.system]
  }
}

resource "xcsh_alert_policy" "system" {
  name      = "client-side-defense-policy"
  namespace = "system"

  annotations = {
    "terraform.f5-sales-demo.com/owner"               = "client-side-defense/system-notifications"
    "terraform.f5-sales-demo.com/receiver-generation" = terraform_data.receiver_generation.id
  }

  receivers {
    # Retain the dependency on receiver creation; the generation annotation
    # makes the policy update survive resolution to an unchanged name.
    name      = xcsh_alert_receiver.system.id
    namespace = xcsh_alert_receiver.system.namespace
  }

  routes {
    group {
      groups = ["SECURITY_CSD"]
    }
    send = {}
  }

  lifecycle {
    prevent_destroy = true
  }
}
