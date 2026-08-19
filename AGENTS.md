# AGENTS.md

These instructions apply to the entire repository.

## Mission and current state

Build a production-quality Go connector between Asterisk and Vtiger CRM and
provide reproducible automation for installing and operating Asterisk/FreePBX
on `cm.gus-global.com`.

The repository is currently a scaffold. `main.go` is placeholder code; do not
infer architecture or completed functionality from it.

## Read before changing code

- `README.md` for scope, known facts, server inventory, and open decisions.
- `documentatnion/tz.odt` for requirements and acceptance criteria.
- `documentatnion/info.odt` for deployment inputs. Never copy credentials from
  it into source, tests, logs, commits, or agent output.
- `/data/gus/vtigercrm/modules/PBXManager` for the current local Vtiger 8.4.0
  contract. The user-provided `/data/gus/vtiger` path was absent during the
  2026-08-19 inventory; verify this on every environment.
- `legacy/asteriskconnector-master` only when historical behavior is relevant.

## Requirement precedence

1. Explicit user decisions and accepted specifications.
2. Current supported Asterisk/Vtiger behavior and verified contracts.
3. Official documentation for the selected versions.
4. Legacy connector behavior.

Do not silently resolve contradictory requirements. In particular, clarify
whether extension 100 participates in the initial ring group or only in the
fallback with the owner's mobile phone.

## Architecture boundaries

Architecture style, dependency injection, Asterisk interface (AMI/ARI/AGI),
persistence, and deployment approach are open decisions. Ask for or produce a
reviewable decision before introducing a large package hierarchy.

- Put executable entry points in `cmd/<name>/` and keep `main` limited to
  configuration, dependency wiring, lifecycle, and exit status.
- Put private packages under `internal/`; use `pkg/` only for an intentionally
  public library.
- Define interfaces where they are consumed and only for real boundaries.
- Keep Asterisk transport, Vtiger transport, call state, recording storage, and
  deployment concerns independently testable.
- Configuration comes from environment or protected files. Validate it once at
  startup and fail with actionable errors.
- Every long-running component must support health checks, graceful shutdown,
  cancellation, and bounded resource use.

## Go standards

Use Go 1.26 and the installed skills relevant to the task. Important defaults:

- clear code over clever code; avoid premature abstraction;
- MixedCaps identifiers, standard acronym casing, focused packages, and no
  `util`/`helper` dumping grounds;
- `context.Context` first for cancellable operations;
- explicit composite-literal fields and initialized slices/maps at API
  boundaries;
- early returns and focused functions;
- checked errors wrapped with `%w`; inspect chains with `errors.Is` or
  `errors.AsType`;
- an error is logged or returned, never both;
- structured `slog` output with no secrets or personal data;
- no `panic` for expected operational failures;
- no unbounded goroutines, channels, queues, retries, or I/O.

Use `//nolint:<name> // reason` only for a verified false positive. Blanket or
unexplained suppressions are forbidden.

## Integration invariants

- Assume telephony events are delivered at least once, may arrive late or out
  of order, and may be replayed after reconnect.
- Make externally visible operations idempotent.
- Preserve a stable call identifier and define valid state transitions.
- Use explicit connect/request/idle timeouts and bounded exponential backoff
  with jitter.
- Authenticate every connector endpoint and apply least privilege to Asterisk,
  CRM, files, and network access.
- Do not put shared secrets or personal data in URLs.
- Recording access must be authorized; paths must not be user-controlled; the
  90-day retention process must be safe with concurrent reads and backups.
- Normalize phone numbers at one documented boundary and test international
  German number formats.

## Testing policy

TDD is mandatory for behavior changes:

1. Add a test that fails for the intended reason.
2. Add the smallest implementation that makes it pass.
3. Refactor while the suite remains green.

Tests are executable specifications, not a coverage-number exercise.

- Use table-driven tests with a `name` field and named `t.Run` subtests.
- Create assertion helpers inside the relevant subtest.
- Co-locate `foo_test.go` with `foo.go` and keep test order aligned with source
  order.
- Use `t.Parallel()` only for genuinely isolated tests.
- Mock interfaces, not concrete implementations.
- Use `httptest` or local fakes for network behavior.
- Put external-service tests behind `//go:build integration`.
- Code that owns goroutines needs race and leak coverage.
- Production Asterisk, Vtiger, phone numbers, recordings, and credentials are
  forbidden in automated tests.

Cover success and failure paths, including duplicate/replayed events,
out-of-order transitions, reconnects, timeouts, invalid payloads, partial
failures, unauthorized requests, shutdown during work, and missing recordings.

## Required checks

Run all checks relevant to the change:

```bash
gofmt -l .
go vet ./...
golangci-lint run ./...
go build ./...
go test -race -shuffle=on ./...
bash bin/coverage-check.sh
```

The formatting command must print nothing. `.golangci.yml` is authoritative for
linting. `.coverage-thresholds.json` is authoritative for coverage and currently
requires at least 80% line coverage. CI must remain green and should include
`govulncheck ./...` before production release.

For contract, integration, installer, firewall, backup, migration, or restore
changes, also run the corresponding non-production acceptance checks and record
what was not verifiable locally.

## Legacy policy

The old Java connector demonstrates these concepts only: FastAGI ingress, AMI
events and Originate, call correlation, Vtiger callbacks, recording links, and
Click-to-Call. Do not assume its event names, FastAGI port 4573, embedded Jetty,
SQLite schema, shared-secret query parameters, `SIP/` channel syntax, XML,
60-second dial timeout, or direct file serving are valid for the new system.

Do not copy legacy source until its license and the new project's license are
compatible. Prefer a clean implementation from documented behavior and current
contracts.

## Server and deployment safety

Use `task ssh` for the target server. Unless the user explicitly authorizes a
mutation, server work is read-only.

Before an authorized change:

1. Confirm host, OS, relevant service/version, config path, and current health.
2. Identify affected users, network exposure, and service interruption.
3. Back up the exact files/data being changed and define rollback.
4. Make the smallest reproducible change.
5. Validate config before reload, then verify health and the acceptance path.

Never commit or print SIP, CRM, AMI/ARI, database, email, or TLS credentials.
Never expose management APIs publicly. Do not restart nginx, Apache, MySQL,
Docker, CRM, Asterisk, firewall, or the host without explicit approval.

Provisioning should be idempotent and version-controlled. Manual commands must
be captured in automation or an operations document once proven.

## Documentation and commits

- Keep `README.md`, configuration examples, operational instructions, and
  acceptance criteria synchronized with behavior.
- Document every environment variable, default, validation rule, and secret
  classification in `.env.example` without real values.
- Record version-specific Asterisk/Vtiger assumptions next to the contract or
  ADR that depends on them.
- Use focused Conventional Commits. Do not commit, push, deploy, or open a PR
  unless the user asks.

## Definition of done

Work is complete only when the requirement is unambiguous, implementation and
tests agree, failure/retry/security behavior is covered, relevant quality gates
pass, operational impact and rollback are known, and documentation is current.
