terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {
  host = "npipe:////.//pipe//docker_engine"
}

resource "docker_image" "jenkins_image" {
  name   = "myjenkins-blueocean:121123112"

  build {
    context    = "./"
    dockerfile = "./Dockerfile"
  }
}

resource "docker_container" "jenkins_container" {
  name  = "jenkins_container"
  image = docker_image.jenkins_image.name

  ports {
    internal = 8080
    external = 8080
  }
}