# Identity as a Service (IDaaS) Platform Blueprint

This document describes the SaaS Identity-as-a-Service platform for the organization. It consolidates the existing technical stack defined in the original architecture deck and expands it with best-in-class design principles used by leading providers such as Okta, Auth0, ForgeRock, Ping Identity, and Azure Entra ID.

## Vision and Goals

| Objective | Description |
|-----------|-------------|
| Developer Experience | Provide SDKs, quickstarts, and tenant self-service so engineering teams can onboard in minutes. |
| Zero-Trust Security | Enforce device posture, phishing-resistant MFA, continuous risk evaluation, and least-privilege access everywhere. |
| Hybrid Compatibility | Offer first-class support for modern apps (OIDC/OAuth2) while keeping legacy LDAP and SAML workloads running without re-platforming. |
| Global Reliability | Deliver 99.99% availability through globally distributed control planes, disaster recovery drills, and automated failover. |
| Compliance & Audit | Maintain auditable trails, policy versioning, and data residency controls to meet SOC 2, ISO 27001, GDPR, and industry regulations. |

## Platform Architecture

The platform uses a self-hosted Zero Trust Network Access (ZTNA) model. Traffic is routed to regional Kubernetes clusters managed by Rancher. Each cluster runs:

* **Keycloak** for tenant-scoped identity services (OIDC, OAuth2, SAML, LDAP federation).
* **OAuth2 Proxy** as a reverse proxy that enforces authentication and authorization before brokering traffic to downstream services.
* **API Gateways** (Kong or Istio) that enforce policies, perform token validation, and broker traffic to downstream services.
* **SCIM Synchronization Service** that handles provisioning and deprovisioning workflows across SaaS and internal apps.
* **YugabyteDB** as the globally replicated data store for identities, sessions, consents, and policy metadata.
* **OpenLDAP/FreeIPA** clusters exposed via Keycloak LDAP storage provider for workloads that require traditional directory access.

Secrets and signing keys are stored in HSM-backed vaults (CloudHSM, AWS KMS, or Azure Key Vault) with automated rotation.

### Identity & Access Protocols

* **OIDC/OAuth2** for modern web, mobile, SPA, and API clients with JWT-based tokens, refresh tokens, dynamic client registration, and device authorization flows.
* **SAML 2.0** for enterprise SaaS federation and legacy SSO.
* **LDAP v3** bindings for POSIX/Unix logins, network gear, and older applications.
* **SCIM 2.0** for automated provisioning/deprovisioning with downstream systems.
* **FIDO2/WebAuthn** and adaptive MFA to provide phishing-resistant authentication.

### Multi-Tenancy Model

* Tenant isolation through Keycloak realms, namespace-scoped Kubernetes deployments, and logically separated LDAP organizational units.
* Shared services (SCIM, observability, CI/CD) operate in control-plane clusters with per-tenant configuration stored in encrypted config stores.
* Support for customer-managed keys and tenant-level audit export to meet high-trust requirements.

### Security Controls

* Token lifecycle management with JWKS endpoints, kid rotation, and mutual TLS for service-to-service calls.
* Fine-grained authorization through Keycloak authorization services, OPA/ORY Keto policies, and attribute-based access control.
* Comprehensive audit logging for admin actions, authentication events, SCIM changes, and API usage, streamed into a SIEM (Splunk, Datadog, Panther).
* Background risk scoring and anomaly detection using UEBA models to drive step-up authentication or session revocation.

### Observability & Compliance

* OpenTelemetry instrumentation for Keycloak, SCIM services, and API gateways.
* Centralized log aggregation using Loki or Elasticsearch/Fluentd/Kibana.
* Metrics stored in Prometheus/Thanos with SLO dashboards in Grafana.
* Audit and compliance pipelines export immutable logs to cloud object storage with retention and legal hold policies.

## Delivery & Operations

### CI/CD Pipeline

* Jenkins orchestrates linting, testing, container builds, security scans, and Helm-based deployments across environments (review apps, staging, prod).
* Helm charts package Kubernetes resources; Argo CD or FluxCD performs GitOps-based reconciliations for declarative environments.
* Security gates include SAST/DAST, IaC scans, container vulnerability scanning, and policy-as-code checks before promotion.

### Repository Topology

```
repo/
├── infra/        # Terraform automation for clusters, DNS, and other infrastructure
├── charts/       # Helm charts for Keycloak, YugabyteDB, SCIM services, observability stack, and the ZTNA proxy
├── apps/         # Source code & Dockerfiles for SCIM sync, admin portal, integration webhooks, and tooling
├── keycloak/     # Realm templates, client registrations, policy JSON, script providers, themes for branding per-tenant
└── ops/          # Runbooks, incident response plans, and audit controls
```

This layout matches the original slide guidance and aligns with GitOps best practices, enabling infrastructure automation alongside application delivery.

### Runbooks & SRE Practices

* **Incident Response**: PagerDuty/Squadcast escalation, runbooks per component, and chaos drills for failover validation.
* **Backups & DR**: Continuous backup of YugabyteDB via xCluster replication, daily snapshots of Keycloak configuration, and quarterly restore exercises.
* **Capacity Planning**: Autoscaling keyed off login throughput, SCIM job volume, and API latency metrics with regional burst capacity.
* **Secrets Management**: HashiCorp Vault or cloud-native secret stores integrated with workload identity, short-lived credentials, and break-glass procedures.

## Customer & Developer Experience

* Tenant admin portal for domain verification, IdP federation (SAML/WS-Fed), policy configuration, and delegated administration.
* SDKs for major languages/frameworks (JavaScript/TypeScript, Python, Java, .NET, Go) with quickstarts and CLI tooling for automation.
* Marketplace of pre-built SaaS integrations (Salesforce, Google Workspace, Atlassian, ServiceNow) using SCIM and SAML/OIDC app catalogs.
* Advanced analytics dashboards for login trends, risk events, provisioning status, and compliance exports.

## MFA Authenticator App

This repository includes the source code for a mobile MFA authenticator app, located in the `apps/mfa-authenticator` directory. The app is built with Flutter and is compatible with the TOTP standard used by Keycloak.

### Features

*   **TOTP Generation:** The app can generate 6-digit TOTP codes from a secret key.
*   **QR Code Scanning:** New accounts can be added by scanning a QR code from Keycloak.

### Building the App

To build the app, you will need to have the Flutter SDK installed. From the `apps/mfa-authenticator` directory, run the following commands:

```bash
flutter pub get
flutter run
```

**Note:** The QR code scanner requires camera permissions. You will need to configure these permissions in the Android and iOS projects before building a release version.
