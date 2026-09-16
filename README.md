# Automated Infrastructure Testing and Validation Using Terraform and Terraform Test

This repository documentation is split into three files:

- **[README.md](README.md)** — this file: project overview, structure, architecture, and learning outcomes
- **[SETUP.md](SETUP.md)** — full environment setup, installation, and infrastructure provisioning steps
- **[DEMO.md](DEMO.md)** — the Terraform Test concepts, the PASS → FAIL → FIX → PASS demonstration, and the full demo/showcase walkthrough

---

# 1. Project Overview

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

# 3. Current Infrastructure

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

# 4. Core DevOps Workflow

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

# 5. Project Learning Outcomes

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

# 6. One-Line Project Summary

> **This project uses Terraform to provision Docker-based application infrastructure and Terraform Test to automatically validate infrastructure requirements before deployment, demonstrating a PASS → FAIL → FIX → PASS infrastructure testing workflow.**
