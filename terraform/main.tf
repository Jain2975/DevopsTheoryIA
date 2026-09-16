resource "docker_network" "app_network" {
  name = "devops-theory-network"
}

resource "docker_volume" "postgres_data" {
  name = "devops-theory-postgres-data"
}

resource "docker_container" "postgres" {
  name  = "devops-theory-postgres"
  image = "postgres:17"

  env = [
    "POSTGRES_USER=taskuser",
    "POSTGRES_PASSWORD=taskpassword",
    "POSTGRES_DB=taskdb"
  ]

  ports {
    internal = 5432
    external = 5432
  }

  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }

  volumes {
    host_path      = abspath("${path.module}/db/init.sql")
    container_path = "/docker-entrypoint-initdb.d/init.sql"
    read_only      = true
}

  networks_advanced {
    name = docker_network.app_network.name
  }
}

resource "docker_image" "backend" {
  name = "devops-theory-backend:latest"

  build {
    context    = "${path.module}/../app/backend"
    dockerfile = "${path.module}/../app/backend/Dockerfile"
  }
}

resource "docker_container" "backend" {
  name  = "devops-theory-backend"
  image = docker_image.backend.name

  env = [
    "DATABASE_URL=postgresql://taskuser:taskpassword@devops-theory-postgres:5432/taskdb"
  ]

  ports {
    internal = 3000
    external = 3001
  }

  networks_advanced {
    name = docker_network.app_network.name
  }

  depends_on = [
    docker_container.postgres
  ]
}