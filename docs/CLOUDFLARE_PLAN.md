# Cloudflare Deployment Plan (Moltworker)

This repo is now refactored to support a Cloudflare-first runtime path (`AGENT_RUNTIME=cloudflare`) so agent execution can be moved off local Apple containers and into Cloudflare Workers.

## Goals

1. Keep runtime simple and maintainable.
2. Keep monthly operating cost <= $15/month.
3. Harden execution path with defense-in-depth controls.

## Proposed Architecture

- **Ingress + controls**: Cloudflare Access + WAF in front of any admin/API endpoints.
- **Agent runtime**: [Moltworker](https://github.com/cloudflare/moltworker) hosted on Cloudflare Workers.
- **Control plane**: NanoClaw (this Node process) calls Moltworker over HTTPS using bearer auth.
- **Data**:
  - Keep SQLite and WhatsApp state local initially for low-risk migration.
  - Optional phase 2: move state to Cloudflare D1 + R2 when needed.

## Runtime Refactor Summary

- Added `AGENT_RUNTIME` (defaults to `cloudflare`).
- Added Cloudflare runtime env vars:
  - `CLOUDFLARE_AGENT_ENDPOINT`
  - `CLOUDFLARE_API_TOKEN`
  - `CLOUDFLARE_REQUEST_TIMEOUT`
- Added Cloudflare execution path in `runContainerAgent()`:
  - POST prompt/session/metadata to Moltworker-compatible endpoint.
  - Parse JSON result and map to existing `ContainerOutput` contract.
  - Preserve callback flow so messaging path remains unchanged.
- Startup now skips Apple Container checks when Cloudflare runtime is active.

## Security Controls

### Runtime hardening

- Run on Cloudflare Workers sandbox (no host shell access).
- Use short request timeouts and upstream auth token validation.
- Do not send `.env` wholesale; only pass explicit payload fields.

### Access controls

- Protect operational endpoints behind Cloudflare Access policies.
- Use one service token per environment (dev/staging/prod).
- Rotate `CLOUDFLARE_API_TOKEN` every 30 days.

### Firewall and abuse prevention

- Cloudflare WAF managed rules enabled.
- Rate limit agent endpoint by IP + token identity.
- Block non-HTTPS traffic and pin to known hostnames.

## Cost Envelope (<= $15/month)

Assumptions: personal usage with low background traffic.

- Cloudflare Workers free tier: typically enough for small personal assistants.
- If paid usage is needed, target one paid tier only and keep invocation volume low.
- Optional D1/R2 usage kept minimal (logs + short history retention).

**Operating rule:** if monthly estimate exceeds $12, reduce polling frequency and cap agent invocations before reaching $15.

## Rollout Plan

1. **Phase 1 (now):** Cloudflare runtime path behind env flag (done).
2. **Phase 2:** Deploy Moltworker worker and validate endpoint contract.
3. **Phase 3:** Add Access policy + WAF + rate limits.
4. **Phase 4:** Move persistent state off local disk only if needed.

## Environment Variables

```bash
AGENT_RUNTIME=cloudflare
CLOUDFLARE_AGENT_ENDPOINT=https://<your-moltworker-endpoint>/v1/agent/run
CLOUDFLARE_API_TOKEN=<service-token>
CLOUDFLARE_REQUEST_TIMEOUT=120000
```

## Deployment Runbook

For end-to-end OpenTofu provisioning and rollout commands, see:

- [docs/CLOUDFLARE_DEPLOYMENT.md](./CLOUDFLARE_DEPLOYMENT.md)

## Validation Checklist

- [ ] `npm run typecheck` passes.
- [ ] `npm test` passes.
- [ ] Cloudflare endpoint returns valid JSON with `result` and optional `sessionId`.
- [ ] Access and WAF rules block unauthenticated requests.
