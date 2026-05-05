variable "docker_host" {
  description = "Docker host connection string. Example: unix:///var/run/docker.sock or npipe:////./pipe/docker_engine"
  type        = string
  default     = "unix:///var/run/docker.sock"
}

variable "image_name" {
  description = "Docker image to pull"
  type        = string
  default     = "nginx:latest"
}

variable "container_name" {
  description = "Name for the created container"
  type        = string
  default     = "tutorial-container"
}

variable "internal_port" {
  description = "Port inside the container"
  type        = number
  default     = 80
}

variable "external_port" {
  description = "Port exposed on the host"
  type        = number
  default     = 8000
}

variable "backend_image" {
  description = "Backend image name (built from ../backend)"
  type        = string
  default     = "monkeypop-backend:local"
}

variable "backend_container_name" {
  description = "Name for backend container"
  type        = string
  default     = "backend-container"
}

variable "backend_external_port" {
  description = "Host port for backend"
  type        = number
  default     = 3001
}

variable "frontend_image" {
  description = "Frontend image name (built from ../frontend)"
  type        = string
  default     = "monkeypop-frontend:local"
}

variable "frontend_container_name" {
  description = "Name for frontend container"
  type        = string
  default     = "frontend-container"
}

variable "frontend_external_port" {
  description = "Host port for frontend"
  type        = number
  default     = 3000
}
variable "redis_image" {
  description = "Redis image name"
  type        = string
  default     = "redis:alpine"
}

variable "redis_container_name" {
  description = "Name for redis container"
  type        = string
  default     = "redis"
}

variable "redis_external_port" {
  description = "Host port for redis"
  type        = number
  default     = 6379
}