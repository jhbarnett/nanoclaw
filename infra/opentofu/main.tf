locals {
  tags = ["nanoclaw", var.environment]
}

resource "cloudflare_worker_script" "agent" {
  account_id = var.cloudflare_account_id
  name       = var.worker_name
  content    = file(var.worker_script_path)
}

resource "cloudflare_worker_route" "agent" {
  zone_id     = var.zone_id
  pattern     = var.worker_route_pattern
  script_name = cloudflare_worker_script.agent.name
}

resource "cloudflare_ruleset" "managed_waf" {
  zone_id = var.zone_id
  name    = "nanoclaw-managed-waf-${var.environment}"
  kind    = "zone"
  phase   = "http_request_firewall_managed"

  rules {
    action      = "execute"
    expression  = "true"
    description = "Enable Cloudflare Managed WAF rules"

    action_parameters {
      id = "efb7b8c949ac4650a09736fc376e9aee"
    }
  }
}

resource "cloudflare_ruleset" "api_firewall" {
  zone_id = var.zone_id
  name    = "nanoclaw-api-firewall-${var.environment}"
  kind    = "zone"
  phase   = "http_request_firewall_custom"

  rules {
    action      = "block"
    expression  = "(http.host eq \"${var.access_hostname}\" and not ssl)"
    description = "Block non-HTTPS requests to the agent host"
  }

  rules {
    action      = "managed_challenge"
    expression  = "(http.host eq \"${var.access_hostname}\" and cf.threat_score gt 10)"
    description = "Challenge suspicious traffic before worker execution"
  }
}

resource "cloudflare_ruleset" "agent_rate_limit" {
  zone_id = var.zone_id
  name    = "nanoclaw-agent-rate-limit-${var.environment}"
  kind    = "zone"
  phase   = "http_ratelimit"

  rules {
    action      = "block"
    expression  = "(http.host eq \"${var.access_hostname}\" and http.request.uri.path contains \"/v1/agent/run\")"
    description = "Rate-limit agent execution endpoint"

    ratelimit {
      characteristics     = ["cf.colo.id", "ip.src"]
      period              = 60
      requests_per_period = var.rate_limit_requests_per_minute
      mitigation_timeout  = 60
    }
  }
}

resource "cloudflare_access_application" "agent" {
  count = var.enable_access ? 1 : 0

  zone_id          = var.zone_id
  name             = "nanoclaw-agent-${var.environment}"
  domain           = var.access_hostname
  type             = "self_hosted"
  session_duration = "24h"
  app_launcher_visible = false
}

resource "cloudflare_access_service_token" "nanoclaw" {
  count = var.enable_access ? 1 : 0

  account_id = var.cloudflare_account_id
  name       = "${var.allowed_service_token_name}-${var.environment}"
  duration   = "8760h"
}

resource "cloudflare_access_policy" "agent_service_token" {
  count = var.enable_access ? 1 : 0

  application_id = cloudflare_access_application.agent[0].id
  zone_id        = var.zone_id
  name           = "allow-nanoclaw-service-token"
  precedence     = 1
  decision       = "allow"

  include {
    service_token = [cloudflare_access_service_token.nanoclaw[0].id]
  }
}
