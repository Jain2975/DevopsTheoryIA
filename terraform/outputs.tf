output "network_name" {
  description = "Docker network used by the application"
  value       = docker_network.app_network.name
}

output "postgres_container_name" {
  description = "PostgreSQL container name"
  value       = docker_container.postgres.name
}

output "backend_container_name" {
  description = "Backend container name"
  value       = docker_container.backend.name
}

output "backend_url" {
  description = "Backend API URL"
  value       = "http://localhost:3001"
}