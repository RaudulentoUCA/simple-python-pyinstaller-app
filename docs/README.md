
## El primer archivo main:
```tf
module "dockerindocker" {
  source = "./modules/dockerindocker"
}

module "jenkins" {
  source = "./modules/jenkins"
}

```
Este archivo llama al resto de archivos de configuración que están separados por funcionalidades, hay que tener en cuenta que las rutas que se utilicen serán relativas a este archivo main.

