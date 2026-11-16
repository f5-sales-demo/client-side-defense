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

resource "xcsh_alert_policy" "system" {
  name      = "client-side-defense-policy"
  namespace = "system"

  receivers {
    # The computed ID defers initial adoption until receiver creation and makes
    # Terraform update the dangling reference even when its name is unchanged.
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
