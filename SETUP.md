# Setup Guide — Automated Infrastructure Testing and Validation Using Terraform and Terraform Test

This file covers full environment setup: installing tools, configuring the backend, initializing Terraform, and provisioning and verifying the infrastructure.

See also: **[README.md](README.md)** for the project overview, and **[DEMO.md](DEMO.md)** for the Terraform Test demonstration and showcase walkthrough.

---

# 1. Environment

The project is being developed inside **WSL/Ubuntu**.

Check the installed tools:

```bash
terraform version
docker --version
node --version
npm --version
git --version
```

Expected versions used for this project:

```text
Terraform v1.16.2
Docker 29.1.3
Node.js v24.19.0
npm 11.17.0
Git 2.43.0
```

Docker should also be tested:

```bash
docker run --rm hello-world
```

Expected result:

```text
Hello from Docker!
```

---

# 2. Navigate to the Project

From WSL:

```bash
cd ~/DevopsTheoryIA
```

Check the project:

```bash
ls
```

Expected:

```text
app
terraform
.gitignore
README.md
```

---

# 3. Backend Setup

Move into the backend:

```bash
cd ~/DevopsTheoryIA/app/backend
```

Install dependencies:

```bash
npm install
```

Check the installed dependencies:

```bash
npm list --depth=0
```

The backend uses:

- Express
- PostgreSQL (`pg`)
- dotenv
- TypeScript
- tsx

---

# 4. Backend Environment Variables

Create:

```text
~/DevopsTheoryIA/app/backend/.env
```

Contents:

```env
DATABASE_URL=postgresql://taskuser:taskpassword@localhost:5432/taskdb
```

The `.env` file should **not** be committed to Git.

Verify that the variable is loaded:

```bash
cd ~/DevopsTheoryIA/app/backend

npx tsx -e "import 'dotenv/config'; console.log(process.env.DATABASE_URL)"
```

Expected:

```text
postgresql://taskuser:taskpassword@localhost:5432/taskdb
```

---

# 5. Backend Build

Build the TypeScript backend:

```bash
cd ~/DevopsTheoryIA/app/backend
npm run build
```

Expected:

```text
No TypeScript compilation errors
```

This generates:

```text
app/backend/dist/
```

---

# 6. Dockerfile

The backend Dockerfile is:

```dockerfile
FROM node:24-alpine

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY tsconfig.json ./
COPY src ./src

RUN npm run build

EXPOSE 3000

CMD ["node", "dist/index.js"]
```

---

# 7. Build the Backend Docker Image Manually

This is useful for testing the Dockerfile independently.

```bash
cd ~/DevopsTheoryIA/app/backend

docker build -t devops-theory-backend .
```

Check the image:

```bash
docker images
```

You should see:

```text
devops-theory-backend
```

Terraform will later build/manage this image itself.

---

# 8. PostgreSQL Database Initialization

Terraform uses:

```text
terraform/db/init.sql
```

Current SQL:

```sql
CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO tasks (title, completed)
SELECT 'Learn Terraform', FALSE
WHERE NOT EXISTS (
    SELECT 1
    FROM tasks
    WHERE title = 'Learn Terraform'
);

INSERT INTO tasks (title, completed)
SELECT 'Test Infrastructure', FALSE
WHERE NOT EXISTS (
    SELECT 1
    FROM tasks
    WHERE title = 'Test Infrastructure'
);
```

This allows PostgreSQL to automatically initialize the database when a new PostgreSQL data volume is created.

---

# 9. Important PostgreSQL Initialization Concept

The SQL file is mounted into:

```text
/docker-entrypoint-initdb.d/init.sql
```

inside the PostgreSQL container.

PostgreSQL executes initialization scripts when the database is initialized for the first time.

The database data is stored in a persistent Docker volume:

```text
devops-theory-postgres-data
```

Therefore:

```text
PostgreSQL Container
        │
        ▼
Persistent Docker Volume
        │
        ▼
Database Data
```

The database does not depend on the backend container filesystem.

---

# 10. Terraform Provider

Terraform uses the Docker provider.

`terraform/providers.tf`:

```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}
```

---

# 11. Initialize Terraform

Move to the Terraform directory:

```bash
cd ~/DevopsTheoryIA/terraform
```

Initialize Terraform:

```bash
terraform init
```

Expected:

```text
Initializing the backend...

Initializing provider plugins...

- Installing kreuzwerker/docker...

Terraform has been successfully initialized!
```

The Docker provider used by this project is:

```text
kreuzwerker/docker
```

---

# 12. Terraform Formatting

Before validating or applying Terraform:

```bash
terraform fmt
```

This formats Terraform files.

To see which files were changed:

```bash
terraform fmt -diff
```

---

# 13. Terraform Validation

Run:

```bash
terraform validate
```

Expected:

```text
Success! The configuration is valid.
```

### Purpose

`terraform validate` checks whether the Terraform configuration is syntactically and structurally valid.

It does **not** create the infrastructure.

---

# 14. Terraform Plan

Run:

```bash
terraform plan
```

Terraform calculates what infrastructure it intends to create/change/destroy.

A successful plan for the current project should show approximately:

```text
Plan: 4 to add, 0 to change, 0 to destroy.
```

The resources include:

```text
docker_network.app_network
docker_volume.postgres_data
docker_container.postgres
docker_image.backend
docker_container.backend
```

Note that Terraform's final resource count can reflect dependencies and state/import history; always use the actual plan output shown by Terraform.

---

# 15. Docker Network

The application uses:

```text
devops-theory-network
```

The network allows the backend container to communicate with PostgreSQL using the PostgreSQL container name.

Backend connection:

```text
postgresql://taskuser:taskpassword@devops-theory-postgres:5432/taskdb
```

Important:

Inside Docker, the backend should **not** use:

```text
localhost
```

for PostgreSQL.

Instead it uses:

```text
devops-theory-postgres
```

because Docker's network provides container-to-container name resolution.

---

# 16. Terraform Apply

To create the infrastructure:

```bash
cd ~/DevopsTheoryIA/terraform

terraform apply
```

Terraform will display the execution plan and ask for confirmation:

```text
Do you want to perform these actions?
  Enter a value:
```

Enter:

```text
yes
```

Expected final result:

```text
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```

Outputs:

```text
backend_container_name = "devops-theory-backend"
backend_url = "http://localhost:3001"
network_name = "devops-theory-network"
postgres_container_name = "devops-theory-postgres"
```

---

# 17. Check Docker Containers

After Terraform apply:

```bash
docker ps
```

Expected containers:

```text
devops-theory-backend
devops-theory-postgres
```

The backend should expose:

```text
localhost:3001
```

The PostgreSQL database should expose:

```text
localhost:5432
```

---

# 18. Check Terraform State

Run:

```bash
terraform state list
```

Expected resources:

```text
docker_container.backend
docker_container.postgres
docker_image.backend
docker_network.app_network
docker_volume.postgres_data
```

Terraform state tracks the infrastructure managed by Terraform.

---

# 19. Check Terraform Outputs

Run:

```bash
terraform output
```

Expected:

```text
backend_container_name = "devops-theory-backend"
backend_url = "http://localhost:3001"
network_name = "devops-theory-network"
postgres_container_name = "devops-theory-postgres"
```

To retrieve only the backend URL:

```bash
terraform output backend_url
```

Expected:

```text
http://localhost:3001
```

---

# 20. Verify Backend Health

Run:

```bash
curl http://localhost:3001/health
```

Expected:

```json
{ "status": "healthy" }
```

This confirms that the backend container is running and responding.

---

# 21. Verify Database Through the Application

Run:

```bash
curl http://localhost:3001/tasks
```

Expected similar output:

```json
[
  {
    "id": 2,
    "title": "Test Infrastructure",
    "completed": false,
    "created_at": "..."
  },
  {
    "id": 1,
    "title": "Learn Terraform",
    "completed": false,
    "created_at": "..."
  }
]
```

The exact IDs and timestamps can differ.

---

# 22. Verify PostgreSQL Directly

Enter PostgreSQL:

```bash
docker exec -it devops-theory-postgres psql -U taskuser -d taskdb
```

Run:

```sql
SELECT * FROM tasks;
```

Expected similar output:

```text
 id |        title        | completed |         created_at
----+---------------------+-----------+----------------------------
  1 | Learn Terraform     | f         | ...
  2 | Test Infrastructure | f         | ...
```

Exit PostgreSQL:

```sql
\q
```

---

# 23. Verify Docker Volume

Run:

```bash
docker volume inspect devops-theory-postgres-data
```

The volume should exist.

It should have a Docker mountpoint similar to:

```text
/var/lib/docker/volumes/devops-theory-postgres-data/_data
```

This demonstrates persistent storage for PostgreSQL.

---

# 24. Useful Terraform Commands

### Initialize

```bash
terraform init
```

### Format

```bash
terraform fmt
```

### Validate

```bash
terraform validate
```

### Plan

```bash
terraform plan
```

### Apply

```bash
terraform apply
```

### Show Outputs

```bash
terraform output
```

### Show State

```bash
terraform state list
```

### Run Tests

```bash
terraform test
```

### Show Current State

```bash
terraform show
```

---

# 25. Useful Docker Commands

List running containers:

```bash
docker ps
```

List all containers:

```bash
docker ps -a
```

List images:

```bash
docker images
```

List networks:

```bash
docker network ls
```

Inspect network:

```bash
docker network inspect devops-theory-network
```

List volumes:

```bash
docker volume ls
```

Inspect PostgreSQL volume:

```bash
docker volume inspect devops-theory-postgres-data
```

View backend logs:

```bash
docker logs devops-theory-backend
```

View PostgreSQL logs:

```bash
docker logs devops-theory-postgres
```

Follow backend logs:

```bash
docker logs -f devops-theory-backend
```

Stop following logs:

```text
Ctrl + C
```

---

# 26. Useful Application Commands

Health check:

```bash
curl http://localhost:3001/health
```

Get tasks:

```bash
curl http://localhost:3001/tasks
```

Create a task:

```bash
curl -X POST http://localhost:3001/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Learn Terraform Test"}'
```

Update a task:

```bash
curl -X PATCH http://localhost:3001/tasks/1 \
  -H "Content-Type: application/json" \
  -d '{"completed":true}'
```

Delete a task:

```bash
curl -X DELETE http://localhost:3001/tasks/1
```

Then verify:

```bash
curl http://localhost:3001/tasks
```

---

# 27. PostgreSQL Commands

Enter the database:

```bash
docker exec -it devops-theory-postgres psql -U taskuser -d taskdb
```

Inside PostgreSQL:

```sql
SELECT * FROM tasks;
```

List tables:

```sql
\dt
```

Describe the tasks table:

```sql
\d tasks
```

Exit:

```sql
\q
```

---

# 28. Terraform Import — Historical Setup

During initial development, some Docker resources were created manually before Terraform managed them.

For example, the Docker network was manually created:

```bash
docker network create devops-theory-network
```

Terraform can import an existing resource into its state.

Example:

```bash
terraform import docker_network.app_network devops-theory-network
```

After importing, verify:

```bash
terraform state list
```

The resource should appear:

```text
docker_network.app_network
```

### Important

Importing a resource only adds it to Terraform state.

It does not automatically mean that the existing infrastructure matches the Terraform configuration.

Always run:

```bash
terraform plan
```

after importing.

---

# 29. Important Import Lesson

If Terraform says that importing an existing resource would cause a replacement or unexpected changes, do **not** blindly run:

```bash
terraform apply
```

First inspect:

```bash
terraform plan
```

and determine why the actual infrastructure differs from the Terraform configuration.

This project ultimately moved to having Terraform create and manage the infrastructure cleanly rather than depending on the old manually-created PostgreSQL container.

---

# 30. Port Mapping

Backend:

```text
Host:      3001
Container: 3000
```

Therefore:

```text
http://localhost:3001
```

PostgreSQL:

```text
Host:      5432
Container: 5432
```

Inside Docker, backend connects to:

```text
devops-theory-postgres:5432
```

---

# 31. Complete Fresh-Run Command Sequence

If the project already exists and the Terraform configuration is ready, the normal workflow is:

```bash
cd ~/DevopsTheoryIA/terraform

terraform init
terraform fmt
terraform validate
terraform test
terraform plan
terraform apply
```

Enter:

```text
yes
```

Then:

```bash
docker ps
curl http://localhost:3001/health
curl http://localhost:3001/tasks
terraform state list
terraform output
```

---

# 32. Cleanup — Destroy Terraform Infrastructure

If the infrastructure is no longer needed:

```bash
cd ~/DevopsTheoryIA/terraform

terraform destroy
```

Terraform will ask for confirmation.

Enter:

```text
yes
```

This removes Terraform-managed resources.

---

# 33. Important Warning About the PostgreSQL Volume

The PostgreSQL volume contains database data.

Before destroying infrastructure, understand what happens to:

```text
devops-theory-postgres-data
```

Do not manually delete the volume unless you intentionally want to remove the stored database data.

To inspect it:

```bash
docker volume inspect devops-theory-postgres-data
```

---

# 34. Check for Remaining Containers

After cleanup:

```bash
docker ps -a
```

Check volumes:

```bash
docker volume ls
```

Check networks:

```bash
docker network ls
```

---

# 35. Full Reset for a Fresh Database

Only perform this if the database data can be discarded.

First destroy Terraform infrastructure:

```bash
cd ~/DevopsTheoryIA/terraform
terraform destroy
```

Then, if the volume still exists and you intentionally want a fresh database:

```bash
docker volume rm devops-theory-postgres-data
```

After that:

```bash
terraform apply
```

Enter:

```text
yes
```

PostgreSQL will initialize the empty volume and execute:

```text
terraform/db/init.sql
```

The initial tasks should be recreated.

---

# 36. Troubleshooting

## Terraform command not found

Check:

```bash
terraform version
```

---

## Docker command not found

Check:

```bash
docker --version
```

---

## Terraform provider problem

Run:

```bash
terraform init
```

If necessary:

```bash
terraform init -upgrade
```

---

## Terraform formatting

Run:

```bash
terraform fmt
```

---

## Terraform configuration error

Run:

```bash
terraform validate
```

Then inspect:

```bash
terraform plan
```

---

## Terraform Test failure

Run:

```bash
terraform test
```

Read the assertion's:

```text
error_message
```

For example:

```text
Backend external port must be 3001.
```

Then compare the Terraform configuration with the expected condition in:

```text
tests/infrastructure.tftest.hcl
```

---

## Backend is not responding

Check:

```bash
docker ps
```

Then:

```bash
docker logs devops-theory-backend
```

---

## PostgreSQL is not responding

Check:

```bash
docker ps
```

Then:

```bash
docker logs devops-theory-postgres
```

---

## Backend cannot connect to PostgreSQL

Check the backend environment:

```bash
docker inspect devops-theory-backend
```

The backend should use:

```text
DATABASE_URL=postgresql://taskuser:taskpassword@devops-theory-postgres:5432/taskdb
```

Also check the Docker network:

```bash
docker network inspect devops-theory-network
```

Both containers should be connected.

---

# 37. Common Mistakes to Avoid

### Mistake 1

Using:

```text
localhost
```

for PostgreSQL from the backend container.

Correct:

```text
devops-theory-postgres
```

---

### Mistake 2

Running `terraform apply` after intentionally introducing the test error.

For the failure demonstration, use:

```bash
terraform test
```

without:

```bash
terraform apply
```

---

### Mistake 3

Deleting the PostgreSQL volume unnecessarily.

The volume contains persistent database data.

---

### Mistake 4

Ignoring `.terraform.lock.hcl`.

The lock file should generally be committed.

Do not add:

```text
.terraform.lock.hcl
```

to `.gitignore`.

---

### Mistake 5

Committing `.env`.

The root `.gitignore` should contain:

```gitignore
.env
```

---

# 38. Recommended `.gitignore`

Root:

```gitignore
# Environment variables
.env

# Dependencies
node_modules/

# Build output
dist/

# Terraform
.terraform/
*.tfstate
*.tfstate.*
```

Do not ignore:

```text
.terraform.lock.hcl
```

---

# 39. Final Quick Reference

### Start

```bash
cd ~/DevopsTheoryIA/terraform
```

### Initialize

```bash
terraform init
```

### Format

```bash
terraform fmt
```

### Validate

```bash
terraform validate
```

### Test

```bash
terraform test
```

### Plan

```bash
terraform plan
```

### Apply

```bash
terraform apply
```

### Check Infrastructure

```bash
docker ps
```

### Check Backend

```bash
curl http://localhost:3001/health
```

### Check Tasks

```bash
curl http://localhost:3001/tasks
```

### Check Terraform State

```bash
terraform state list
```

### Check Outputs

```bash
terraform output
```

### Check PostgreSQL

```bash
docker exec -it devops-theory-postgres psql -U taskuser -d taskdb
```

Then:

```sql
SELECT * FROM tasks;
```

Exit:

```sql
\q
```

### Destroy

```bash
terraform destroy
```

---
