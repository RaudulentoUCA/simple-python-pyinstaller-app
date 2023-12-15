terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

resource "docker_volume" "jenkins-docker-certs" {
  name = "jenkins-docker-certs"
}

resource "docker_volume" "jenkins-data" {
  name = "jenkins-data"
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
  depends_on   = [docker_image.jenkins_image]
  name         = "jenkins_container"
  image        = docker_image.jenkins_image.name
  network_mode = "jenkins"
  restart      = "on-failure"

  env = [
    "DOCKER_TLS_CERTDIR=/certs",
  ]

  volumes {
    volume_name = docker_volume.jenkins-docker-certs.name
    container_path = "/certs/client"
  }

  volumes {
    volume_name = docker_volume.jenkins-data.name
    container_path = "/var/jenkins_home"
  }

  volumes {
    volume_name     = "host-home-volume"
    container_path  = "/home"
  }

  command = [
    "bash",
    "-c",
    "DOCKER_HOST=tcp://docker:2376 DOCKER_CERT_PATH=/certs/client DOCKER_TLS_VERIFY=1 JAVA_OPTS=-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true /usr/local/bin/jenkins.sh"
  ]

  ports {
    internal = 8080
    external = 8080
  }
}