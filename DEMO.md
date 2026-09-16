# Demo & Showcase Guide — Automated Infrastructure Testing and Validation Using Terraform and Terraform Test

This file covers Terraform Test concepts and the full **PASS → FAIL → FIX → PASS** demonstration used to showcase automated infrastructure validation.

See also: **[README.md](README.md)** for the project overview, and **[SETUP.md](SETUP.md)** if you haven't provisioned the infrastructure yet.

---

# 1. Terraform Test

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

# 2. Understanding the Terraform Test

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

# 3. Important Terraform Test Concepts

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

# 4. What the Current Tests Validate

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

# 5. IMPORTANT DEMO: PASS → FAIL → FIX → PASS

This is the main demonstration for the project.

The purpose is to prove that Terraform Test can detect an infrastructure configuration error automatically.

---

# 6. Step 1 — Confirm Everything Currently Passes

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

# 7. Step 2 — Introduce an Intentional Infrastructure Error

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

# 8. Step 3 — Validate the Broken Configuration

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

# 9. Why Did the Test Fail?

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

# 10. Important Point: We Did Not Apply the Error

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

# 11. Step 4 — Fix the Configuration

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

# 12. Step 5 — Run the Tests Again

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

# 13. Optional: Apply After Fixing

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

# 14. Useful Verification Sequence

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

# 15. Terraform Test vs Terraform Validate

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

# 16. Terraform Test vs Terraform Apply

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

# 17. Recommended Demo Order for IA

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

# 18. Complete PASS → FAIL → PASS Command Sequence

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

# 19. Main Project Demonstration

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

# 20. Final IA Demo Checklist

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
