# Como realizar el proceso de despliegue
El despliegue tal como se indica en la práctica ha de realizarse mediante Terraform, cuyo proceso, es el siguiente:

## Inicialización del proyecto Terraform
Este es el primer paso para realizar el despliegue, tras instalar Terraform, si fuera necesario, nos vamos al directorio de trabajo, en este caso, donde se encuentre el archivo ***main.tf***, y aplicamos el siguiente comando, ***terraform init***, el cual va a identificar y descargar las dependencias, inicializa el estado y valida la configuración.

## Creación de la infraestructura
Tras inicializar el proyecto, el paso siguiente es este, donde realizamos ***terraform apply***, lo cual, aplicará los archivos de configuración del directorio actual y nos mostrará la salida de aquello que se ha creado.

## Acceso a Jenkins
Tras esto, podemos acceder a Jenkins, abrimos el navegador y nos dirigimos a ***http://localhost:8080***, y esperamos a que aparezca la págine **Unlock Jenkins**, lo cual, nos pedirá una contraseña de administrador, a la que podremos acceder, introduciendo en la línea de comandos: ***docker logs jenkins-blueocean***, entre dos bloques de astéricos, se encontrará nuestra contraseña de administrador, la introducimos en la página de Jenkins y procedemos a crear nuestro usuario propio.

## Creación del pipeline
Una vez tenemos nuestro usuario, será necesario realizar un *Fork*, tal como en el que nos encontramos, del repositorio [simple-python-pyinstaller-app](https://github.com/jenkins-docs/simple-python-pyinstaller-app). Tras ello, accedemos a Jenkins, clickamos sobre **create new jobs**, justo debajo de **Welcome to Jenkins**, introducimos el nombre del proyecto Pipeline, y seleccionamos sobre Pipeline propiamente. Una vez dentro, nos dirigimos hacia **Pipeline section**, en el campo **Definition**, escogemos **Pipeline script from SCM**, escogemos **Git** y especificamos el directorio de nuestro repositorio del Fork. Tras esto, procedemos a crear el archivo ***Jenkinsfile***, que será donde definamos nuestro Pipeline. Por último, nos quedaría subirlo al repositorio y arrancar el programa.

# Explicación de los ejercicios
## Archivo principal, main.tf
```tf
module "dockerindocker" {
  source = "./modules/dockerindocker" 
}

module "jenkins" {
  source = "./modules/jenkins"
}

```
Este archivo llama al resto de archivos de configuración que están separados por funcionalidades, hay que tener en cuenta que las rutas que se utilicen serán relativas a este archivo main.


## El archivo .tf de la carpeta modules/jenkins/:
```tf
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
    "DOCKER_HOST=tcp://docker:2376",
    "DOCKER_CERT_PATH=/certs/client",
    "DOCKER_TLS_VERIFY=1",
    "JAVA_OPTS=-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true",
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

  ports {
    internal = 8080
    external = 8080
  }
}
```

La primera parte se utiliza para especificar que se utilizará terraform, y los proveedores que se utilizarán. Además de especificar los volúmenes que se utilizarán.
```tf
terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "~> 3.0.2"              # Versión del proveedor de docker
    }
  }
}

resource "docker_volume" "jenkins-docker-certs" {
  name = "jenkins-docker-certs"
}

resource "docker_volume" "jenkins-data" {
  name = "jenkins-data"
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

En la última parte se crea el contenedor con la imagen hecha anteriormente, se utiliza una instrucción de dependencia para que la creación tenga que esperar a que se complete la imagen, se le da un nombre, se especifican los volúmenes con sus rutas a utilizar y se establece que se utilizarán los puertos 8080, tanto en la máquina host como en el contendor.
```tf
resource "docker_container" "jenkins_container" {
  depends_on   = [docker_image.jenkins_image]    # dependencia de la imagen
  name         = "jenkins_container"
  image        = docker_image.jenkins_image.name
  network_mode = "jenkins"
  restart      = "on-failure"                     # se vuelve a encender si no se apaga de forma manual

  env = [
    "DOCKER_HOST=tcp://docker:2376",              # se comunica con el dockerindocker para obtener información
    "DOCKER_CERT_PATH=/certs/client",
    "DOCKER_TLS_VERIFY=1",
    "JAVA_OPTS=-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true",
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

  ports {
    internal = 8080
    external = 8080
  }
}
```


## Archivo Dockerfile
El archivo dockerfile utilizado es el mismo que se nos proporciona en el tutorial ofrecido por el enunciado de la práctica:
https://www.jenkins.io/doc/tutorials/build-a-python-app-with-pyinstaller/
```Dockerfile
FROM jenkins/jenkins:2.426.1-jdk17
USER root
RUN apt-get update && apt-get install -y lsb-release
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
  https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get update && apt-get install -y docker-ce-cli
USER jenkins
RUN jenkins-plugin-cli --plugins "blueocean:1.27.9 docker-workflow:572.v950f58993843"
```
