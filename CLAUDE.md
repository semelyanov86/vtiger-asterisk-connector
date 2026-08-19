# Project instructions for Claude

## Project

This repository will contain a production-quality Go connector between
Asterisk and Vtiger CRM, plus reproducible automation for a turnkey Asterisk
installation on `cm.gus-global.com`.

Read these sources before making changes:

1. `AGENTS.md` — canonical engineering and safety rules.
2. `README.md` — scope, current facts, server baseline, and open decisions.
3. `documentatnion/tz.odt` and `documentatnion/info.odt` — product requirements
   and acceptance data. The directory name is intentionally recorded as it
   currently exists.
4. Current Vtiger `PBXManager` code. In this workspace it is at
   `/data/gus/vtigercrm`; the originally stated `/data/gus/vtiger` path is not
   present. Verify the path rather than assuming it.
5. `legacy/asteriskconnector-master` only for behavioral discovery.

The current Go program is a scaffold. Do not describe placeholder behavior as
implemented functionality.

## Source-of-truth policy

- Explicitly accepted decisions and the specification define product behavior.
- The live supported Asterisk and Vtiger contracts define integration details.
- Official documentation for the selected versions outranks legacy code.
- Legacy Java code is never authoritative. Do not copy its security model,
  dependencies, event parsing, ports, XML format, storage, or SIP assumptions
  without current verification and an explicit design decision.
- Record contradictions instead of silently choosing one interpretation. The
  known routing conflict is whether extension 100 rings initially or only after
  101–103 time out.

## Workflow

1. Inspect `git status --short` and read the relevant specification and code.
2. For changes involving architecture, first confirm the architecture style,
   dependency injection approach, Asterisk interface, and persistence model.
3. Write or update a failing test before production code.
4. Implement the smallest coherent change and keep boundaries explicit.
5. Update documentation and `.env.example` whenever behavior or configuration
   changes.
6. Run all applicable quality gates before claiming completion.

For complex work, use `/start-task` when the repository's metaswarm commands
are available. Never commit, push, deploy, or modify the server unless the user
explicitly asks for that action.

## Required Go practices

Use the installed Go skills that match the task, especially:

- `golang-project-layout` for package boundaries and executable layout;
- `golang-design-patterns` before choosing architecture or lifecycle patterns;
- `golang-code-style` and `golang-naming` for new or changed Go code;
- `golang-error-handling` for error chains and structured logging;
- `golang-testing` for unit, integration, race, and leak tests;
- `golang-lint` and `golang-continuous-integration` for quality gates;
- `golang-troubleshooting` for failures, reconnects, races, and deadlocks;
- `golang-modernize` when newer Go 1.26 APIs simplify code safely.

Keep `main` minimal. Application wiring belongs under `cmd/`; private business
and integration code belongs under `internal/`. Do not create `pkg/` unless a
package is intentionally supported for external consumers. Do not introduce
layers or interfaces without a real boundary or testing need.

- Pass `context.Context` first and honor cancellation.
- Use graceful shutdown for HTTP servers, Asterisk connections, workers, and
  storage.
- Keep goroutine ownership and shutdown responsibility explicit.
- Use `log/slog`; keep messages stable and put values in structured fields.
- Never log secrets, authorization data, raw phone numbers, or recording URLs.
- Check every returned error. Wrap with useful `%w` context and either return
  or log an error, never both.
- Use `errors.Is`/`errors.AsType` for error inspection.
- Keep identifiers idiomatic MixedCaps; preserve standard acronym casing.
- Avoid global mutable state, hidden `init` side effects, reflection, and
  premature abstraction.

## Telephony and CRM correctness

Treat Asterisk events as at-least-once and potentially out of order. Handlers
must be idempotent, reconnect-safe, bounded by timeouts, and testable with
fakes. Preserve a stable call identity across channels and event phases. Define
which component owns state transitions before implementation.

Test at minimum:

- inbound, outbound, answered, busy, rejected, no-answer, and hangup flows;
- reconnect, duplicate, replayed, delayed, and out-of-order events;
- Click-to-Call authorization and failure behavior;
- Vtiger timeouts, non-2xx responses, invalid payloads, and retries;
- recording access, missing files, retention, and unauthorized requests;
- graceful shutdown while work is in flight.

Ordinary tests must not dial real numbers, access production CRM, or use the
production Asterisk server. Integration tests use `//go:build integration` and
explicit non-production configuration.

## Server safety

`task ssh` connects as `root@cm.gus-global.com`. Default to read-only
inspection. Before any mutation:

- verify the exact host and current state;
- state the intended change and blast radius;
- prepare backup/rollback and a validation command;
- do not expose secrets in commands, logs, patches, or chat;
- do not restart telephony, web, database, or firewall services without explicit
  authorization;
- do not open SIP, RTP, AMI, ARI, AGI, or connector ports until the security
  design is approved.

Prefer version-controlled, idempotent deployment automation over undocumented
interactive server changes.

## Quality gates

The blocking minimum is:

```bash
gofmt -l .
go vet ./...
golangci-lint run ./...
go build ./...
go test -race -shuffle=on ./...
bash bin/coverage-check.sh
```

`gofmt -l .` must print nothing. `.golangci.yml` is the linter source of truth;
`.coverage-thresholds.json` is the coverage source of truth. Run integration,
contract, vulnerability, and deployment checks when the change touches those
areas. Never weaken a gate merely to make a change pass.

## Definition of done

A change is complete only when its behavior is specified, tests cover success
and failure paths, all relevant gates pass, sensitive data is protected,
operational impact and rollback are documented, and README/spec/config examples
remain accurate.
