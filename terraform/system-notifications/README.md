# System CSD notifications

This root owns only `system/client-side-defense-receiver` and
`system/client-side-defense-policy`. The application root owns the separate
Page Tamper receiver in `client-side-defense`; its live email destination is
the source of truth. No destination input or public destination output is needed.

The existing system policy is adopted with a declarative import. Import is a
no-op once the resource is managed. The policy keeps its single `SECURITY_CSD`
Send route and platform notification defaults. A local `terraform_data` generation
resource is replaced when the receiver changes. Its persistent ID is recorded in
policy ownership annotations, forcing an in-place update during restoration even
when the receiver name is unchanged. The API resolves the reference by name and
namespace without hardcoded UIDs. Both system resources have deletion protection.

## Ownership and deployment

State uses the encrypted, locked S3 backend
`terraform-tfstate-xc/f5-sales-demo/client-side-defense-system-notifications.tfstate`
in `us-east-1`, guarded to the existing state-owning AWS account. This is separate
from the AWS application state because these system objects were never owned by
that root. Application refresh and CSD registration errors remain independent.
Do not use targeting, refresh suppression, state edits, or domain recreation.

Execute on the verified Ubuntu workstation with the approved `sso` AWS profile
and an authenticated `XCSH_API_TOKEN` supplied through the process environment.
The provider URL and resource identities are fixed to this tenant. Verify that
no other state owns these system objects before initial adoption.

```bash
umask 077
export AWS_PROFILE=sso
terraform -chdir=terraform/system-notifications init -input=false -lockfile=readonly
terraform -chdir=terraform/system-notifications plan -input=false -out=/private/path/notifications.tfplan
terraform -chdir=terraform/system-notifications show -json /private/path/notifications.tfplan > /private/path/notifications.plan.json
```

Keep plans, logs, JSON and raw state private: they contain the destination even
when human-readable output marks it sensitive. Bind the reviewed plan to the
exact merged source, verified executor and cloud identity. The initial plan must
create only the missing receiver and its local generation value, and import/update
the existing policy in place. A follow-up adoption of the generation value changes
only that local value and the policy ownership annotations/reference. Reject
system-object deletion/replacement, unrelated resources, destination differences,
route changes or public outputs. Keep `adopt_existing_policy=true` for this tenant;
`false` exists for isolated mock tests, not to avoid import errors.

Apply the exact reviewed saved plan under the scoped deployment authorization.
Independently read both receivers and the policy: verify destination equality,
unchanged policy UID and routes, and that the policy receiver UID resolves to the
new receiver. Then run a full refreshed plan:

```bash
terraform -chdir=terraform/system-notifications apply -input=false /private/path/notifications.tfplan
terraform -chdir=terraform/system-notifications plan -input=false -detailed-exitcode
```

Exit code `0` establishes Terraform idempotence; `2` means changes remain and `1`
means failure. Routine plans also propagate future dedicated-destination changes.
If a managed receiver disappears, inspect its deletion and ownership first;
the plan will propose restoration, local generation replacement and an in-place
policy reference update. An unchanged generation makes repeated plans stable.

## Validation and acceptance

Run `bash tests/test-system-notifications.sh` from the repository root. It uses
isolated local Terraform data and mock credentials with no backend or live writes.
The tests cover source identity, sensitive destination inheritance, system
reference, preserved route/defaults, and rejection of missing/empty destinations.
Live saved-plan review and the final no-change plan additionally verify import,
reference repair and provider/backend behavior that mocks cannot establish.

This repair establishes notification configuration. It does not establish CSD
registration, alert generation or delivery. Issue #1296 still requires successful
authoritative CSD collection/status reads and console visibility of the expected
root before the separate Page Tamper testing gate in #1259 can proceed.
