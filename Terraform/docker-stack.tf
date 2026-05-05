/*
  Build and run backend and frontend Docker containers using local Dockerfiles.
*/

resource "docker_image" "backend" {
  name = var.backend_image
  build {
    context    = "../backend"
    dockerfile = "Dockerfile"
  }
  keep_locally = true
}

resource "docker_container" "backend" {
  image = docker_image.backend.image_id
  name  = var.backend_container_name

  env = [
    "REDIS_URL=redis://redis:6379"
  ]

  ports {
    internal = 3001
    external = var.backend_external_port
  }

  networks_advanced {
    name = docker_network.app_network.name
  }

  depends_on = [docker_container.redis]
}

resource "docker_image" "frontend" {
  name = var.frontend_image
  build {
    context    = "../frontend"
    dockerfile = "Dockerfile"
  }
  keep_locally = true
}

resource "docker_container" "frontend" {
  image = docker_image.frontend.image_id
  name  = var.frontend_container_name

  ports {
    internal = 80
    external = var.frontend_external_port
  }
}
