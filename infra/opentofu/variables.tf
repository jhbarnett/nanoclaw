variable "cloudflare_api_token" {
  description = "Cloudflare API token with Workers, Zone, Rulesets, and Access permissions."
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID."
  type        = string
}

variable "zone_id" {
  description = "Cloudflare Zone ID for your domain."
  type        = string
}

variable "zone_name" {
  description = "Cloudflare zone name (example.com)."
  type        = string
}

variable "environment" {
  description = "Deployment environment name (dev/staging/prod)."
  type        = string
  default     = "prod"
}

variable "worker_name" {
  description = "Worker script name for Moltworker endpoint."
  type        = string
  default     = "nanoclaw-moltworker"
}

variable "worker_script_path" {
  description = "Path to the built worker JavaScript file."
  type        = string
  default     = "./worker/dist/index.js"
}

variable "worker_route_pattern" {
  description = "Route pattern for the worker (for example: agent.example.com/*)."
  type        = string
}

variable "enable_access" {
  description = "Enable Cloudflare Access app + service token policy for the worker hostname."
  type        = bool
  default     = true
}

variable "access_hostname" {
  description = "Hostname protected by Cloudflare Access (for example: agent.example.com)."
  type        = string
}

variable "allowed_service_token_name" {
  description = "Name for the Access service token used by NanoClaw control-plane requests."
  type        = string
  default     = "nanoclaw-agent-service-token"
}

variable "rate_limit_requests_per_minute" {
  description = "Per-client request cap for the agent endpoint."
  type        = number
  default     = 120
}
