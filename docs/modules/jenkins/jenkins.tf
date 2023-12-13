terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {
  host = "npipe:////.//pipe//docker_engine"
}

resource "docker_image" "jenkins_image" {
  name = "myjenkins-blueocean:121123112"

  build {
    context    = "./modules"
    dockerfile = "Dockerfile.dockerfile"
  }
}

resource "docker_container" "jenkins_container" {
  depends_on = [docker_image.jenkins_image]
  name  = "jenkins_container"
  image = docker_image.jenkins_image.name

  ports {
    internal = 8080
    external = 8080
  }
}