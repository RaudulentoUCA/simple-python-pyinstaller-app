terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {
  host = "npipe:////./pipe/docker_engine"
}

resource "docker_network" "jenkins_network" {
  name = "jenkins"
}

resource "docker_volume" "jenkins-docker-certs" {
  name = "jenkins-docker-certs"
}

resource "docker_volume" "jenkins-data" {
  name = "jenkins-data"
}

resource "docker_container" "jenkins_docker" {
  name  = "jenkins-docker"
  image = "docker:dind"
  rm    = true
  privileged = true

  env = [
    "DOCKER_TLS_CERTDIR=/certs",
  ]

  volumes {
    volume_name    = docker_volume.jenkins-docker-certs.name
    container_path = "/certs/client"
  }

  volumes {
    volume_name    = docker_volume.jenkins-data.name
    container_path = "/var/jenkins_home"
  }

  ports {
    internal = 3000
    external = 3000
  }

  ports {
    internal = 5000
    external = 5000
  }

  ports {
    internal = 2376
    external = 2376
  }

  networks_advanced {
    name = docker_network.jenkins_network.name
    aliases = ["docker"]
  }
}