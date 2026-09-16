run "validate_infrastructure" {
  command = plan

  # -----------------------------
  # Docker Network
  # -----------------------------

  assert {
    condition     = docker_network.app_network.name == "devops-theory-network"
    error_message = "The Docker network name is incorrect."
  }

  # -----------------------------
  # PostgreSQL Volume
  # -----------------------------

  assert {
    condition     = docker_volume.postgres_data.name == "devops-theory-postgres-data"
    error_message = "The PostgreSQL volume name is incorrect."
  }

  # -----------------------------
  # PostgreSQL Container
  # -----------------------------

  assert {
    condition     = docker_container.postgres.name == "devops-theory-postgres"
    error_message = "PostgreSQL container name is incorrect."
  }

  assert {
    condition     = docker_container.postgres.image == "postgres:17"
    error_message = "PostgreSQL must use the postgres:17 image."
  }

  assert {
    condition     = docker_container.postgres.ports[0].internal == 5432
    error_message = "PostgreSQL internal port must be 5432."
  }

  assert {
    condition     = docker_container.postgres.ports[0].external == 5432
    error_message = "PostgreSQL external port must be 5432."
  }

  # -----------------------------
  # PostgreSQL Configuration
  # -----------------------------

  assert {
    condition     = contains(docker_container.postgres.env, "POSTGRES_DB=taskdb")
    error_message = "PostgreSQL database configuration is incorrect."
  }

  assert {
    condition     = contains(docker_container.postgres.env, "POSTGRES_USER=taskuser")
    error_message = "PostgreSQL user configuration is incorrect."
  }

  assert {
    condition     = contains(docker_container.postgres.env, "POSTGRES_PASSWORD=taskpassword")
    error_message = "PostgreSQL password configuration is incorrect."
  }

  # -----------------------------
  # PostgreSQL Network
  # -----------------------------

  assert {
    condition = anytrue([
      for network in docker_container.postgres.networks_advanced :
      network.name == docker_network.app_network.name
    ])

    error_message = "PostgreSQL must be connected to the application network."
  }

  # -----------------------------
  # PostgreSQL Persistent Volume
  # -----------------------------

  assert {
    condition = anytrue([
      for volume in docker_container.postgres.volumes :
      volume.volume_name == docker_volume.postgres_data.name
    ])

    error_message = "PostgreSQL must use the persistent data volume."
  }

  # -----------------------------
  # Backend Container
  # -----------------------------

  assert {
    condition     = docker_container.backend.name == "devops-theory-backend"
    error_message = "Backend container name is incorrect."
  }

  assert {
    condition     = docker_container.backend.image == "devops-theory-backend:latest"
    error_message = "Backend must use the expected Docker image."
  }

  assert {
    condition     = docker_container.backend.ports[0].internal == 3000
    error_message = "Backend internal port must be 3000."
  }

  assert {
    condition     = docker_container.backend.ports[0].external == 3001
    error_message = "Backend external port must be 3001."
  }

  # -----------------------------
  # Backend Network
  # -----------------------------

  assert {
    condition = anytrue([
      for network in docker_container.backend.networks_advanced :
      network.name == docker_network.app_network.name
    ])

    error_message = "Backend must be connected to the application network."
  }

  # -----------------------------
  # Backend Database Connection
  # -----------------------------

  assert {
    condition = contains(
      docker_container.backend.env,
      "DATABASE_URL=postgresql://taskuser:taskpassword@devops-theory-postgres:5432/taskdb"
    )

    error_message = "Backend DATABASE_URL is incorrect."
  }
}