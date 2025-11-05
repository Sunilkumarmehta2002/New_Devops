terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.0"
    }
  }
}

provider "docker" {}

# Pull Docker images (if already pushed to Docker Hub)
# If not yet, you can also build from local Dockerfiles using Ansible
resource "docker_image" "backend" {
  name = "pro_backend:latest"
  build {
    context = "${path.module}/../../backend"
  }
}

resource "docker_image" "frontend" {
  name = "pro_frontend:latest"
  build {
    context = "${path.module}/../../frontend"
  }
}

resource "docker_container" "backend" {
  name  = "pro_backend"
  image = docker_image.backend.name
  ports {
    internal = 5000
    external = 5000
  }
  env = [
    "MONGO_URL=${var.mongo_uri}"
  ]
}

resource "docker_container" "frontend" {
  name  = "pro_frontend"
  image = docker_image.frontend.name
  ports {
    internal = 3000
    external = 3000
  }
}
