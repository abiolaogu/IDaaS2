CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE "Tenant" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE TABLE "User" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    password TEXT NOT NULL,
    "displayName" TEXT NOT NULL,
    roles TEXT[] NOT NULL,
    "tenantId" UUID NOT NULL REFERENCES "Tenant"(id) ON DELETE CASCADE,
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    CONSTRAINT user_email_tenant_unique UNIQUE (email, "tenantId")
);

CREATE TABLE "Application" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    "clientId" TEXT NOT NULL UNIQUE,
    "clientSecret" TEXT NOT NULL,
    "redirectUris" TEXT[] NOT NULL,
    "tenantId" UUID NOT NULL REFERENCES "Tenant"(id) ON DELETE CASCADE,
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE TYPE "AuditAction" AS ENUM (
    'USER_CREATED',
    'USER_AUTHENTICATED',
    'TOKEN_ISSUED',
    'APPLICATION_REGISTERED'
);

CREATE TABLE "AuditLog" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "actorId" UUID NULL REFERENCES "User"(id) ON DELETE SET NULL,
    "tenantId" UUID NULL REFERENCES "Tenant"(id) ON DELETE SET NULL,
    action "AuditAction" NOT NULL,
    metadata JSONB NOT NULL,
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_auditlog_tenant ON "AuditLog" ("tenantId");
CREATE INDEX idx_auditlog_actor ON "AuditLog" ("actorId");
