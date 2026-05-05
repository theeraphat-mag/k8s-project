terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

# Configure the Docker provider
provider "docker" {
  host = var.docker_host
  # Examples:
  # - Linux/macOS (default): "unix:///var/run/docker.sock"
  # - Windows (named pipe): "npipe:////./pipe/docker_engine"
}

# Pull an image
resource "docker_image" "nginx" {
  name         = var.image_name
  keep_locally = false
}

# Run a container
resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = var.container_name

  ports {
    internal = var.internal_port
    external = var.external_port
  }
}