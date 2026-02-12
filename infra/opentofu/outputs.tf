output "worker_name" {
  description = "Deployed Cloudflare worker script name."
  value       = cloudflare_worker_script.agent.name
}

output "agent_route_pattern" {
  description = "Route pattern attached to the worker."
  value       = cloudflare_worker_route.agent.pattern
}

output "agent_endpoint" {
  description = "HTTPS endpoint NanoClaw should call for agent execution."
  value       = "https://${var.access_hostname}/v1/agent/run"
}

output "access_service_token_id" {
  description = "Cloudflare Access service token ID for NanoClaw requests."
  value       = var.enable_access ? cloudflare_access_service_token.nanoclaw[0].id : null
}

output "access_service_token_client_id" {
  description = "Cloudflare Access Client ID header value (CF-Access-Client-Id)."
  value       = var.enable_access ? cloudflare_access_service_token.nanoclaw[0].client_id : null
}

output "access_service_token_client_secret" {
  description = "Cloudflare Access Client Secret header value (CF-Access-Client-Secret)."
  value       = var.enable_access ? cloudflare_access_service_token.nanoclaw[0].client_secret : null
  sensitive   = true
}
