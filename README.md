# Automated Infrastructure Testing and Validation Using Terraform and Terraform Test

## 1. Project Overview

This project demonstrates how **Terraform** can be used to provision and manage application infrastructure and how **Terraform Test** can automatically validate that the infrastructure configuration satisfies predefined requirements.

### Main Technologies

- Terraform
- Terraform Test
- Docker
- PostgreSQL
- Node.js
- TypeScript
- Express
- Git

### Main Objective

The main focus of this project is:

> **Automated Infrastructure Testing and Validation Using Terraform and Terraform Test**

The web application is only used to demonstrate that the provisioned infrastructure actually supports a working application.

The important DevOps workflow is:

```text
Terraform Configuration
        ↓
terraform validate
        ↓
terraform plan
        ↓
terraform test
        ↓
terraform apply
        ↓
Running Infrastructure
        ↓
Application Verification
```

---

# 2. Project Structure

The project should have the following structure:

```text
DevopsTheoryIA/
│
├── app/
│   │
│   ├── backend/
│   │   ├── src/
│   │   │   ├── index.ts
│   │   │   └── db.ts
│   │   │
│   │   ├── tests/
│   │   │   └── db.test.ts
│   │   │
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   ├── package-lock.json
│   │   └── tsconfig.json
│   │
│   └── frontend/
│
├── terraform/
│   ├── providers.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   │
│   ├── db/
│   │   └── init.sql
│   │
│   └── tests/
│       └── infrastructure.tftest.hcl
│
├── .gitignore
└── README.md
```

---

# 3. Environment

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

# 4. Navigate to the Project

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

# 5. Backend Setup

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

# 6. Backend Environment Variables

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

# 7. Backend Build

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

# 8. Dockerfile

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

# 9. Build the Backend Docker Image Manually

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

# 10. PostgreSQL Database Initialization

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

# 11. Important PostgreSQL Initialization Concept

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

# 12. Terraform Provider

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

# 13. Initialize Terraform

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

# 14. Terraform Formatting

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

# 15. Terraform Validation

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

# 16. Terraform Plan

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

# 17. Docker Network

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

# 18. Terraform Apply

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

# 19. Check Docker Containers

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

# 20. Check Terraform State

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

# 21. Check Terraform Outputs

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

# 22. Verify Backend Health

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

# 23. Verify Database Through the Application

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

# 24. Verify PostgreSQL Directly

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

# 25. Verify Docker Volume

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

# 26. Terraform Test

Terraform Test validates Terraform configurations using test files.

The test file is:

```text
terraform/tests/infrastructure.tftest.hcl
```

Run:

```bash
cd ~/DevopsTheoryIA/terraform

terraform test
```

Expected:

```text
tests/infrastructure.tftest.hcl... in progress
  run "validate_infrastructure"... pass
tests/infrastructure.tftest.hcl... tearing down
tests/infrastructure.tftest.hcl... pass

Success! 1 passed, 0 failed.
```

---

# 27. Understanding the Terraform Test

The test contains:

```hcl
run "validate_infrastructure" {
  command = plan
```

This means the test evaluates the infrastructure using a Terraform plan rather than permanently applying the test configuration.

Inside the test are assertions such as:

```hcl
assert {
  condition     = docker_container.backend.ports[0].external == 3001
  error_message = "Backend external port must be 3001."
}
```

The test checks:

```text
Expected value
      ↓
Terraform configuration
      ↓
Assertion
      ↓
PASS / FAIL
```

---

# 28. Important Terraform Test Concepts

## `run`

Defines a test run.

Example:

```hcl
run "validate_infrastructure" {
```

---

## `command`

Specifies how Terraform evaluates the test.

Current project:

```hcl
command = plan
```

This is useful because the test can validate the planned infrastructure without permanently changing the real infrastructure.

---

## `assert`

Defines an individual test condition.

Example:

```hcl
assert {
  condition     = docker_container.backend.ports[0].external == 3001
  error_message = "Backend external port must be 3001."
}
```

---

## `condition`

The actual expression that must be true.

Example:

```hcl
docker_container.backend.ports[0].external == 3001
```

If true:

```text
PASS
```

If false:

```text
FAIL
```

---

## `error_message`

The message displayed if the assertion fails.

Example:

```hcl
error_message = "Backend external port must be 3001."
```

This makes the test failure understandable.

---

# 29. What the Current Tests Validate

The infrastructure tests check:

### Docker Network

```text
Network name
```

Expected:

```text
devops-theory-network
```

### PostgreSQL Volume

```text
Volume name
```

Expected:

```text
devops-theory-postgres-data
```

### PostgreSQL Container

Checks:

```text
Container name
PostgreSQL image
Internal port
External port
```

Expected:

```text
devops-theory-postgres
postgres:17
5432
5432
```

### PostgreSQL Configuration

Checks:

```text
POSTGRES_DB
POSTGRES_USER
POSTGRES_PASSWORD
```

Expected:

```text
taskdb
taskuser
taskpassword
```

### PostgreSQL Network

Checks that PostgreSQL is connected to:

```text
devops-theory-network
```

### PostgreSQL Persistent Storage

Checks that PostgreSQL uses:

```text
devops-theory-postgres-data
```

### Backend Container

Checks:

```text
Container name
Docker image
Internal port
External port
```

Expected:

```text
devops-theory-backend
devops-theory-backend:latest
3000
3001
```

### Backend Network

Checks that the backend is connected to:

```text
devops-theory-network
```

### Backend Database Connection

Checks:

```text
DATABASE_URL
```

Expected:

```text
postgresql://taskuser:taskpassword@devops-theory-postgres:5432/taskdb
```

---

# 30. IMPORTANT DEMO: PASS → FAIL → FIX → PASS

This is the main demonstration for the project.

The purpose is to prove that Terraform Test can detect an infrastructure configuration error automatically.

---

# 31. Step 1 — Confirm Everything Currently Passes

First:

```bash
cd ~/DevopsTheoryIA/terraform
```

Run:

```bash
terraform fmt
terraform validate
terraform test
```

Expected:

```text
Success! 1 passed, 0 failed.
```

Take a screenshot of this for the IA demonstration if required.

---

# 32. Step 2 — Introduce an Intentional Infrastructure Error

Open:

```text
terraform/main.tf
```

Find the backend container:

```hcl
resource "docker_container" "backend" {
```

Inside its `ports` block, the correct configuration is:

```hcl
ports {
  internal = 3000
  external = 3001
}
```

Temporarily change it to:

```hcl
ports {
  internal = 3000
  external = 9999
}
```

Do **NOT** run:

```bash
terraform apply
```

The purpose is to test the configuration before deployment.

---

# 33. Step 3 — Validate the Broken Configuration

Run:

```bash
cd ~/DevopsTheoryIA/terraform

terraform fmt
terraform validate
terraform test
```

Expected:

```text
tests/infrastructure.tftest.hcl... in progress
  run "validate_infrastructure"... fail
```

The important failure should be:

```text
Backend external port must be 3001.
```

And the final result should indicate a failed test, similar to:

```text
Failure! 0 passed, 1 failed.
```

The exact Terraform diagnostic formatting may vary by Terraform version.

---

# 34. Why Did the Test Fail?

The Terraform configuration says:

```hcl
external = 9999
```

But the test expects:

```hcl
docker_container.backend.ports[0].external == 3001
```

Therefore:

```text
9999 == 3001
```

is:

```text
FALSE
```

So Terraform Test reports:

```text
FAIL
```

This demonstrates automated infrastructure validation.

---

# 35. Important Point: We Did Not Apply the Error

Notice that we did not run:

```bash
terraform apply
```

Therefore, the running backend infrastructure should still have the previous configuration.

This demonstrates the idea:

```text
Bad Terraform Configuration
          ↓
terraform test
          ↓
FAIL
          ↓
Deployment can be stopped
```

Instead of:

```text
Bad Configuration
      ↓
terraform apply
      ↓
Broken Infrastructure
```

---

# 36. Step 4 — Fix the Configuration

Open:

```text
terraform/main.tf
```

Change:

```hcl
external = 9999
```

back to:

```hcl
external = 3001
```

Save the file.

---

# 37. Step 5 — Run the Tests Again

Run:

```bash
cd ~/DevopsTheoryIA/terraform

terraform fmt
terraform validate
terraform test
```

Expected:

```text
tests/infrastructure.tftest.hcl... in progress
  run "validate_infrastructure"... pass
tests/infrastructure.tftest.hcl... tearing down
tests/infrastructure.tftest.hcl... pass

Success! 1 passed, 0 failed.
```

This completes:

```text
PASS
 ↓
Introduce Error
 ↓
FAIL
 ↓
Fix Error
 ↓
PASS
```

This is the key project demonstration.

---

# 38. Optional: Apply After Fixing

After the test passes, the infrastructure can safely be applied:

```bash
terraform plan
```

Verify the plan.

Then:

```bash
terraform apply
```

Enter:

```text
yes
```

Then verify:

```bash
docker ps
```

And:

```bash
curl http://localhost:3001/health
```

Expected:

```json
{ "status": "healthy" }
```

---

# 39. Useful Verification Sequence

For a complete demonstration, the following sequence can be used.

## Validate

```bash
cd ~/DevopsTheoryIA/terraform
terraform fmt
terraform validate
```

Expected:

```text
Success! The configuration is valid.
```

## Test

```bash
terraform test
```

Expected:

```text
Success! 1 passed, 0 failed.
```

## Plan

```bash
terraform plan
```

## Apply

```bash
terraform apply
```

Enter:

```text
yes
```

## Verify Containers

```bash
docker ps
```

## Verify Backend

```bash
curl http://localhost:3001/health
```

## Verify Database

```bash
curl http://localhost:3001/tasks
```

---

# 40. Useful Terraform Commands

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

# 41. Useful Docker Commands

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

# 42. Useful Application Commands

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

# 43. PostgreSQL Commands

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

# 44. Terraform Import — Historical Setup

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

# 45. Important Import Lesson

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

# 46. Current Infrastructure

The final infrastructure is:

```text
                     Docker Network
                  devops-theory-network
                         │
              ┌──────────┴──────────┐
              │                     │
              ▼                     ▼
      Backend Container       PostgreSQL Container
      devops-theory-backend   devops-theory-postgres
              │                     │
        Port 3001:3000        Port 5432:5432
              │                     │
              └──────────┬──────────┘
                         │
                         ▼
              PostgreSQL Volume
              devops-theory-postgres-data
```

---

# 47. Port Mapping

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

# 48. Terraform Test vs Terraform Validate

These commands have different purposes.

## terraform validate

Checks:

```text
Is the Terraform configuration structurally valid?
```

Example:

```bash
terraform validate
```

It does not verify that every infrastructure requirement is correct.

---

## terraform test

Checks:

```text
Does the Terraform configuration satisfy the expected infrastructure conditions?
```

Example:

```bash
terraform test
```

For example:

```hcl
assert {
  condition = docker_container.backend.ports[0].external == 3001
}
```

This is an infrastructure requirement.

---

# 49. Terraform Test vs Terraform Apply

## Terraform Test

Used for:

```text
Automated validation
```

Current tests use:

```hcl
command = plan
```

The test evaluates the configuration and tears down its test run.

---

## Terraform Apply

Used for:

```text
Actually creating/updating infrastructure
```

Command:

```bash
terraform apply
```

Therefore the desired workflow is:

```text
terraform fmt
       ↓
terraform validate
       ↓
terraform test
       ↓
terraform plan
       ↓
terraform apply
```

---

# 50. Recommended Demo Order for IA

For the final presentation/demo:

### Part 1 — Show Project

```bash
cd ~/DevopsTheoryIA
tree
```

If `tree` is not installed:

```bash
sudo apt install tree
```

Then:

```bash
tree
```

---

### Part 2 — Show Terraform

```bash
cd ~/DevopsTheoryIA/terraform
```

Show:

```text
providers.tf
main.tf
variables.tf
outputs.tf
tests/infrastructure.tftest.hcl
db/init.sql
```

---

### Part 3 — Validate

```bash
terraform fmt
terraform validate
```

Show:

```text
Success! The configuration is valid.
```

---

### Part 4 — Terraform Test PASS

```bash
terraform test
```

Show:

```text
Success! 1 passed, 0 failed.
```

---

### Part 5 — Introduce Intentional Error

Change:

```hcl
external = 3001
```

to:

```hcl
external = 9999
```

Do not apply.

Run:

```bash
terraform fmt
terraform validate
terraform test
```

Show the failure:

```text
Backend external port must be 3001.
```

---

### Part 6 — Fix

Change:

```hcl
external = 9999
```

back to:

```hcl
external = 3001
```

Run:

```bash
terraform fmt
terraform validate
terraform test
```

Show:

```text
Success! 1 passed, 0 failed.
```

---

### Part 7 — Apply

```bash
terraform plan
terraform apply
```

Enter:

```text
yes
```

---

### Part 8 — Verify Infrastructure

```bash
docker ps
```

---

### Part 9 — Verify Application

```bash
curl http://localhost:3001/health
```

Then:

```bash
curl http://localhost:3001/tasks
```

---

### Part 10 — Verify Database

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

---

# 51. Complete Fresh-Run Command Sequence

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

# 52. Complete PASS → FAIL → PASS Command Sequence

This is the most important IA demonstration.

## Initial PASS

```bash
cd ~/DevopsTheoryIA/terraform

terraform fmt
terraform validate
terraform test
```

Expected:

```text
Success! 1 passed, 0 failed.
```

---

## Introduce Error

Edit:

```text
terraform/main.tf
```

Change:

```hcl
external = 3001
```

to:

```hcl
external = 9999
```

---

## Run Broken Test

```bash
terraform fmt
terraform validate
terraform test
```

Expected:

```text
FAIL
```

with:

```text
Backend external port must be 3001.
```

Do **not** apply the broken configuration.

---

## Fix

Change:

```hcl
external = 9999
```

back to:

```hcl
external = 3001
```

---

## Final PASS

```bash
terraform fmt
terraform validate
terraform test
```

Expected:

```text
Success! 1 passed, 0 failed.
```

---

# 53. Cleanup — Destroy Terraform Infrastructure

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

# 54. Important Warning About the PostgreSQL Volume

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

# 55. Check for Remaining Containers

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

# 56. Full Reset for a Fresh Database

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

# 57. Troubleshooting

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

# 58. Common Mistakes to Avoid

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

# 59. Recommended `.gitignore`

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

# 60. Project Learning Outcomes

After completing the project, the following concepts can be demonstrated:

1. Infrastructure as Code using Terraform.
2. Docker infrastructure provisioning using Terraform.
3. Terraform providers and resources.
4. Terraform state management.
5. Terraform variables and outputs.
6. Docker networking.
7. Persistent Docker volumes.
8. Automated PostgreSQL initialization.
9. Infrastructure validation using `terraform validate`.
10. Infrastructure testing using `terraform test`.
11. Assertions using Terraform Test.
12. Plan-based infrastructure testing.
13. Detecting infrastructure configuration errors automatically.
14. Preventing incorrect infrastructure from being deployed.
15. Verifying infrastructure after deployment.

---

# 61. Core DevOps Workflow

The complete project demonstrates:

```text
              Infrastructure Code
                     │
                     ▼
              terraform fmt
                     │
                     ▼
             terraform validate
                     │
                     ▼
               terraform test
                     │
              ┌──────┴──────┐
              │             │
             PASS          FAIL
              │             │
              ▼             ▼
        terraform plan     Fix code
              │             │
              ▼             │
        terraform apply ◄───┘
              │
              ▼
       Running Infrastructure
              │
              ▼
      Application Verification
```

---

# 62. Main Project Demonstration

The most important concept to explain during the IA is:

> Terraform provisions the infrastructure, while Terraform Test automatically verifies that the infrastructure configuration satisfies predefined requirements before deployment.

The intentional failure demonstrates that the testing system can detect an incorrect infrastructure configuration.

Example:

```text
Expected backend external port:
3001

Incorrect configuration:
9999

Terraform Test:
FAIL

Error:
Backend external port must be 3001.
```

After correction:

```text
Expected:
3001

Actual:
3001

Terraform Test:
PASS
```

This provides a clear demonstration of **automated infrastructure testing and validation**.

---

# 63. Final Quick Reference

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

# 64. Final IA Demo Checklist

Before the final demonstration, verify:

- [ ] Terraform installed
- [ ] Docker working
- [ ] Backend builds successfully
- [ ] Terraform initialized
- [ ] `terraform fmt` works
- [ ] `terraform validate` passes
- [ ] `terraform test` passes
- [ ] Backend container exists
- [ ] PostgreSQL container exists
- [ ] Docker network exists
- [ ] PostgreSQL volume exists
- [ ] Database initializes automatically
- [ ] `/health` works
- [ ] `/tasks` works
- [ ] Terraform state contains infrastructure
- [ ] Terraform outputs are available
- [ ] Intentional test failure demonstrated
- [ ] Configuration fixed
- [ ] Terraform Test passes again

---

# 65. One-Line Project Summary

> **This project uses Terraform to provision Docker-based application infrastructure and Terraform Test to automatically validate infrastructure requirements before deployment, demonstrating a PASS → FAIL → FIX → PASS infrastructure testing workflow.**
