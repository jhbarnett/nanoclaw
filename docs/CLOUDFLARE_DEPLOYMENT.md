# Cloudflare Deployment with OpenTofu

This guide deploys NanoClaw's Cloudflare-side components using **OpenTofu** and the **Cloudflare provider**.

## What gets provisioned

The OpenTofu stack in `infra/opentofu` provisions:

1. **Worker runtime route** for your Moltworker-compatible Worker endpoint.
2. **Managed WAF ruleset** for baseline protection.
3. **Custom firewall rules** (force HTTPS + challenge suspicious requests).
4. **Rate limiting** for `/v1/agent/run`.
5. **Cloudflare Access** application + service token policy for machine-to-machine calls.

This keeps the deployment simple while adding concrete security controls.

## Prerequisites

- Cloudflare account + domain in Cloudflare.
- OpenTofu installed (`tofu`).
- A built Worker artifact (default path expected by IaC: `./worker/dist/index.js`).
- Cloudflare API token with:
  - Workers Scripts/Routes edit
  - Zone Rulesets edit
  - Access applications/policies/service tokens edit

## 1) Configure variables

```bash
cd infra/opentofu
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set:

- `cloudflare_api_token`
- `cloudflare_account_id`
- `zone_id`
- `zone_name`
- `worker_route_pattern` (example: `agent.example.com/*`)
- `access_hostname` (example: `agent.example.com`)

## 2) Deploy infrastructure

```bash
tofu init
tofu plan
tofu apply
```

After apply, run:

```bash
tofu output
```

Capture these values:

- `agent_endpoint`
- `access_service_token_client_id`
- `access_service_token_client_secret`

## 3) Configure NanoClaw runtime

Set the runtime to Cloudflare and wire credentials:

```bash
AGENT_RUNTIME=cloudflare
CLOUDFLARE_AGENT_ENDPOINT=https://agent.example.com/v1/agent/run
CLOUDFLARE_API_TOKEN=<upstream-bearer-token-used-by-your-worker>
CLOUDFLARE_ACCESS_CLIENT_ID=<tofu output access_service_token_client_id>
CLOUDFLARE_ACCESS_CLIENT_SECRET=<tofu output access_service_token_client_secret>
CLOUDFLARE_REQUEST_TIMEOUT=120000
```

## 4) Security hardening checklist

- Keep Access enabled (`enable_access=true`).
- Rotate `CLOUDFLARE_API_TOKEN` and Access service token credentials every 30 days.
- Keep WAF managed rules + custom firewall rules enabled.
- Keep endpoint rate limit low enough to control abuse and cost.
- Audit Worker logs weekly for blocked/challenged traffic patterns.

## 5) Cost guardrails (target <= $15/month)

- Start on Cloudflare free usage envelope where possible.
- Keep `rate_limit_requests_per_minute` conservative.
- Cap NanoClaw invocation volume (fewer high-value runs > many low-value runs).
- Alert at ~$12 projected monthly usage to stay under budget.

## 6) Rollback

To remove Cloudflare resources managed by this stack:

```bash
tofu destroy
```

> Only run destroy if this OpenTofu project is the authoritative source for those resources.
