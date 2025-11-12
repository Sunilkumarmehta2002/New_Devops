terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.0"
    }
  }
}

provider "docker" {}

variable "mongo_url" {
  description = "MongoDB connection string"
  type        = string
}

locals {
  # Choose the effective Mongo URL:
  # - If the user provided nothing or provided a localhost URL, prefer the
  #   internal `pro_mongo` container (so the backend connects to the Docker
  #   network name `pro_mongo`).
  # - Otherwise use the provided `mongo_url` (e.g. Atlas connection string).
  effective_mongo_url = (
    length(trimspace(var.mongo_url)) == 0 ||
    lower(trimspace(var.mongo_url)) == "mongodb://localhost:27017" ||
    lower(trimspace(var.mongo_url)) == "mongodb+srv://sunilkumarmehta:S6X56ipXTDoS2cUH@fitmitra.bssymqz.mongodb.net/fitmitra?retryWrites=true&w=majority"
  ) ? "mongodb://pro_mongo:27017/provertos" : var.mongo_url
}

variable "dockerhub_username" {
  description = "DockerHub username"
  type        = string
  default     = "sunilkumarmehta2002"
}

variable "frontend_mode" {
  description = "frontend mode: 'dev' uses Vite image, 'prod' uses production nginx image"
  type        = string
  default     = "dev"
}

variable "frontend_dev_image" {
  description = "Frontend dev image name"
  type        = string
  default     = "provertos_frontend:latest"
}

variable "frontend_prod_image" {
  description = "Frontend production image name (nginx)"
  type        = string
  default     = "provertos_frontend_prod:latest"
}

locals {
  frontend_image = var.frontend_mode == "prod" ? var.frontend_prod_image : var.frontend_dev_image
  frontend_internal_port = var.frontend_mode == "prod" ? 80 : 3000
}

resource "docker_container" "backend" {
  name  = "pro_backend"
  image = "provertos_backend:latest"

  # The app listens on port 4000 inside the container; map host 5000 -> container 4000
  ports {
    internal = 4000
    external = 5000
  }

  restart = "always"

  env = [
    "MONGO_URL=${local.effective_mongo_url}"
  ]

  networks_advanced {
    name = docker_network.pro_net.name
  }
}

resource "docker_container" "frontend" {
  name  = "pro_frontend"
  image = local.frontend_image

  ports {
    internal = local.frontend_internal_port
    external = 3000
  }

  restart = "always"

  networks_advanced {
    name = docker_network.pro_net.name
  }
}

# Local MongoDB container used for development when an Atlas URL is not provided
resource "docker_image" "mongo_image" {
  name = "mongo:6.0"
}

resource "docker_container" "mongo" {
  name  = "pro_mongo"
  image = docker_image.mongo_image.name

  ports {
    internal = 27017
    external = 27017
  }

  restart = "always"

  networks_advanced {
    name = docker_network.pro_net.name
  }
}

resource "docker_network" "pro_net" {
  name = "provertos_network"
}
