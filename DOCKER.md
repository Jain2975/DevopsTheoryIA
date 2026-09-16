## Docker Environment Cleanup

Use these commands when you want to completely reset the Docker environment and rebuild the infrastructure from Terraform.

> **Warning:** These commands remove the existing Docker containers, images, volumes, and project data. PostgreSQL data stored in Docker volumes will be deleted.

### 1. Remove all Docker containers

```bash
docker rm -f $(docker ps -aq)
```

### 2. Remove all Docker images

```bash
docker rmi -f $(docker images -aq)
```

### 3. Remove all Docker volumes

```bash
docker volume rm $(docker volume ls -q)
```

> This deletes the PostgreSQL database data stored in Docker volumes.

### 4. Remove Docker networks

```bash
docker network rm $(docker network ls -q)
```

> Docker's default networks such as `bridge`, `host`, and `none` may show errors because they cannot be removed. This is normal.

### 5. Verify the Docker environment is clean

```bash
docker ps -a
docker images
docker volume ls
docker network ls
```

After cleanup, the project-specific containers, images, volumes, and the `devops-theory-network` network should no longer exist.

The infrastructure can then be recreated using Terraform:

```bash
cd ~/DevopsTheoryIA/terraform
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```
