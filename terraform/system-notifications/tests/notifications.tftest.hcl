mock_provider "xcsh" {
  mock_data "xcsh_alert_receiver" {
    defaults = {
      email = { email = "alerts@example.test" }
    }
  }
}

variables {
  adopt_existing_policy = false
}

run "system_notification_contract" {
  command = apply

  assert {
    condition     = data.xcsh_alert_receiver.dedicated.name == "csd-page-tamper-alert-receiver" && data.xcsh_alert_receiver.dedicated.namespace == "client-side-defense"
    error_message = "The existing dedicated receiver must be the destination source."
  }

  assert {
    condition     = xcsh_alert_receiver.system.name == "client-side-defense-receiver" && xcsh_alert_receiver.system.namespace == "system" && xcsh_alert_receiver.system.email.email == data.xcsh_alert_receiver.dedicated.email.email
    error_message = "The system receiver must inherit the dedicated receiver destination."
  }

  assert {
    condition     = issensitive(xcsh_alert_receiver.system.email.email)
    error_message = "The inherited destination must remain sensitive."
  }

  assert {
    condition     = xcsh_alert_policy.system.name == "client-side-defense-policy" && xcsh_alert_policy.system.namespace == "system" && length(xcsh_alert_policy.system.receivers) == 1 && one(xcsh_alert_policy.system.receivers).name == xcsh_alert_receiver.system.id && one(xcsh_alert_policy.system.receivers).namespace == "system"
    error_message = "The existing system policy must reference exactly the managed system receiver."
  }

  assert {
    condition     = length(xcsh_alert_policy.system.routes) == 1 && one(xcsh_alert_policy.system.routes).group.groups == tolist(["SECURITY_CSD"]) && one(xcsh_alert_policy.system.routes).send != null && one(xcsh_alert_policy.system.routes).notification_parameters == null && xcsh_alert_policy.system.notification_parameters == null
    error_message = "Preserve the SECURITY_CSD Send route and platform notification defaults."
  }
}

run "reject_missing_destination" {
  command = plan

  override_data {
    target = data.xcsh_alert_receiver.dedicated
    values = {
      email = { email = tostring(null) }
    }
  }

  expect_failures = [data.xcsh_alert_receiver.dedicated]
}

run "reject_empty_destination" {
  command = plan

  override_data {
    target = data.xcsh_alert_receiver.dedicated
    values = {
      email = { email = "" }
    }
  }

  expect_failures = [data.xcsh_alert_receiver.dedicated]
}
