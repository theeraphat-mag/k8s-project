variable "namespace_name" {
  description = "Name of the Kubernetes namespace"
  type        = string
  default     = "monkeypop"
}

variable "redis_url" {
  description = "Redis connection string"
  type        = string
  default     = "redis://redis:6379"
}

variable "api_key" {
  description = "API Key for backend authentication"
  type        = string
  default     = "monkey-secret-key"
  sensitive   = true
}
