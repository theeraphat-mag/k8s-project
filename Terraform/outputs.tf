output "container_id" {
  description = "ID of the created Docker container"
  value       = docker_container.nginx.id
}

output "external_port" {
  description = "External host port mapped to the container"
  value       = docker_container.nginx.ports[0].external
}

output "backend_container_id" {
  description = "ID of the backend container"
  value       = docker_container.backend.id
}

output "backend_external_port" {
  description = "Host port mapped to backend"
  value       = docker_container.backend.ports[0].external
}

output "frontend_container_id" {
  description = "ID of the frontend container"
  value       = docker_container.frontend.id
}

output "frontend_external_port" {
  description = "Host port mapped to frontend"
  value       = docker_container.frontend.ports[0].external
}

output "redis_container_id" {
  description = "ID of the redis container"
  value       = docker_container.redis.id
}

output "redis_external_port" {
  description = "Host port mapped to redis"
  value       = docker_container.redis.ports[0].external
}
