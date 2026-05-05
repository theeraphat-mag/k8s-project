/*
  Redis service for backend data storage
*/

resource "docker_image" "redis" {
  name         = var.redis_image
  keep_locally = false
}

resource "docker_container" "redis" {
  image = docker_image.redis.image_id
  name  = var.redis_container_name

  ports {
    internal = 6379
    external = var.redis_external_port
  }

  # Ensure redis is accessible to backend on the same network
  networks_advanced {
    name = docker_network.app_network.name
  }
}

resource "docker_network" "app_network" {
  name = "monkeypop-network"
}
