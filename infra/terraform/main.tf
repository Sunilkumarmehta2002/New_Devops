# main.tf




resource "docker_container" "backend" {
  name  = "provertos_backend"
  image = docker_image.backend.name
  ports {
    internal = 5000
    external = 5000
  }
  env = [
    "MONGO_URL=${var.mongo_url}"
  ]
}

resource "docker_container" "frontend" {
  name  = "provertos_frontend"
  image = docker_image.frontend.name
  ports {
    internal = 3000
    external = 3000
  }
  depends_on = [docker_container.backend]
}


resource "docker_image" "backend" {
  name = "provertos_backend:latest"
  build {
    context    = "./../../backend"
    dockerfile = "Dockerfile"
  }
}


resource "docker_image" "frontend" {
  name = "provertos_frontend:latest"
  build {
    context    = "./../../frontend"
    dockerfile = "Dockerfile"
  }
}
