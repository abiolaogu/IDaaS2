# IDaaS SaaS Reference Implementation

This repository contains a deployable reference implementation of an Identity-as-a-Service (IDaaS) multi-tenant SaaS platform. It includes:

- A TypeScript/Express API with tenant-aware user, application, and authentication endpoints.
- PostgreSQL persistence managed with Prisma ORM and automated migrations.
- Audit logging for critical identity events.
- Automated Jest integration tests that exercise end-to-end flows.
- Docker images and Compose orchestration for production-like deployments.
- GitHub Actions CI pipeline for linting, testing, and Prisma schema validation.

## Architecture Overview

| Layer | Technology | Purpose |
| --- | --- | --- |
| API | Node.js 20, Express, TypeScript | REST endpoints, multi-tenant logic |
| Data | PostgreSQL 15 | Durable storage for tenants, users, applications, audit logs |
| ORM | Prisma 5 | Schema management, type-safe data access |
| Auth | JSON Web Tokens | Tenant-scoped access tokens with role claims |
| Validation | Zod | Declarative payload validation |
| Observability | Morgan | Request logging |
| Security | bcrypt | Password hashing |

### Key Capabilities

- **Tenant onboarding** via `/api/tenants`.
- **User lifecycle management** with tenant role enforcement.
- **Application registration** issuing OAuth-style client credentials.
- **Authentication** returning signed JWT access tokens.
- **Audit trail** capturing user and application events.

## Prerequisites

- Node.js 20+
- npm 9+
- Docker & Docker Compose (for local DB and containerized deployments)

## Getting Started

1. **Install dependencies**
   ```bash
   npm install
   ```

2. **Generate Prisma client**
   ```bash
   npx prisma generate
   ```

3. **Start infrastructure**
   ```bash
   docker compose up -d postgres
   ```

4. **Apply database migrations**
   ```bash
   npx prisma migrate deploy
   ```

5. **Run the API in development mode**
   ```bash
   npm run dev
   ```

The API will be available at `http://localhost:3000` by default.

### Example Workflow

```bash
# Create a tenant
curl -X POST http://localhost:3000/api/tenants \
  -H 'Content-Type: application/json' \
  -d '{"name":"Acme Corp","slug":"acme"}'

# Bootstrap an admin for the tenant
npm run bootstrap:admin -- --tenant-slug acme --email admin@acme.com --password Secur3P@ss --name "Acme Admin"

# Authenticate to obtain a JWT
token=$(curl -s -X POST http://localhost:3000/api/auth/token \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@acme.com","password":"Secur3P@ss","tenantSlug":"acme"}' | jq -r '.token')

# Use the token to create a standard user
curl -X POST http://localhost:3000/api/users \
  -H "Authorization: Bearer $token" \
  -H 'Content-Type: application/json' \
  -d '{"email":"user@acme.com","password":"UserP@ss1","displayName":"User","roles":["user"]}'
```

The bootstrap script uses the same validation rules as the API to avoid bypassing guardrails.

## Testing

Run the full integration test suite. It expects a PostgreSQL instance reachable on `localhost:5433` with database `idaas_test`, username `idaas_test`, and password `idaas_test` (the CI pipeline provisions this automatically).

```bash
# Start an ephemeral Postgres instance for testing
DockerID=$(docker run -d --rm \
  -e POSTGRES_USER=idaas_test \
  -e POSTGRES_PASSWORD=idaas_test \
  -e POSTGRES_DB=idaas_test \
  -p 5433:5432 \
  postgres:15-alpine)

npm test

docker stop "$DockerID"
```

The Jest configuration automatically deploys Prisma migrations and cleans tables between tests.

## Linting

```bash
npm run lint
```

## Docker Deployment

Build and run the platform with Docker Compose:

```bash
docker compose up --build
```

Environment variables for the API service can be overridden via the Compose file or a `.env` file.

## Continuous Integration

GitHub Actions configuration in `.github/workflows/ci.yml` executes linting, Prisma validation, and tests against a PostgreSQL service on every push and pull request.

## Project Structure

```
├── prisma
│   ├── migrations              # Database migrations
│   └── schema.prisma          # Data model and migrations source
├── src
│   ├── controllers            # HTTP controllers
│   ├── middleware             # Authentication middleware
│   ├── routes                 # Express routers
│   ├── services               # Domain logic
│   ├── utils                  # Shared utilities
│   └── server.ts              # Application entrypoint
├── tests                      # Jest integration tests
├── scripts                    # Operational helper scripts
├── Dockerfile                 # Production container build
├── docker-compose.yml         # Local orchestration
└── .github/workflows/ci.yml   # CI/CD pipeline
```

## Security Notes

- Always configure a strong `JWT_SECRET` before deploying to production.
- Use secrets management (e.g., AWS Secrets Manager, HashiCorp Vault) rather than plaintext environment variables.
- Enforce HTTPS termination and secure cookie policies at your ingress layer.
- Enable database TLS in production environments.

## Next Steps

- Integrate with external identity providers via SAML/OIDC federation.
- Add multi-factor authentication and adaptive risk scoring.
- Expand audit analytics and reporting dashboards.
- Implement customer-facing admin UI consuming these APIs.
