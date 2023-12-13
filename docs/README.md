
## El primer archivo main:
```tf
module "dockerindocker" {
  source = "./modules/dockerindocker" 
}

module "jenkins" {
  source = "./modules/jenkins"            //llamada al archivo que crea el contenedor de jenkins
}

```
Este archivo llama al resto de archivos de configuración que están separados por funcionalidades, hay que tener en cuenta que las rutas que se utilicen serán relativas a este archivo main.


## El archivo .tf de la carpeta modules/jenkins/:
```tf
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
```

La primera parte se utiliza para especificar que se utilizará terraform, y los proveedores que se utilizarán.
```tf
terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "~> 3.0.2"              # Versión del proveedor de docker
    }
  }
}

provider "docker" {                            # Esta parte es necesaria solo para windows (copiada directamente de la práctica de terraform)
  host = "npipe:////.//pipe//docker_engine"
}
```

En esta segunda parte se crea la imagen que posteriormente se utilizará para crear un contenedor, para ello se utiliza un Dockerfile escrito previamente que se encuenta una carpeta más arriba de lo que está este archivo .tf, pero como la ruta a utilizar es desde el primer archivo main, el contexto se establece a ./modules.
```tf
resource "docker_image" "jenkins_image" {
  name = "myjenkins-blueocean:121123112"      # Nombre de la imagen

  build {
    context    = "./modules"
    dockerfile = "Dockerfile.dockerfile"
  }
}
```

En la última parte se crea el contenedor con la imagen hecha anteriormente, se utiliza una instrucción para que la creación tenga que esperar a que se complete la imagen, se le da un nombre, y se establece que se utilizarán los puertos 8080, tanto en la máquina host como en el contendor.
```tf
resource "docker_container" "jenkins_container" {
  depends_on = [docker_image.jenkins_image]
  name  = "jenkins_container"
  image = docker_image.jenkins_image.name

  ports {
    internal = 8080
    external = 8080
  }
}
```
