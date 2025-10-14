# Slide Highlights Extracted from "IDaaS .pptx"

## Slide 3: Introduction to IDaaS
- Introduction to IDaaS
- IDaaS provides scalable, cloud-based identity and access management as a service.
It supports authentication, authorization, and user lifecycle management across diverse applications and platforms.
Modern engineering teams rely on IDaaS to unify identity across cloud, mobile, and on-premises systems.
IDaaS enhances security by centralizing identity controls, enabling MFA, and supporting zero trust architectures.
It reduces operational complexity by offloading identity infrastructure and enabling rapid integration with modern and legacy apps.
- Include examples of how your team's current projects could benefit from centralized identity management to make the content relatable.
- Introduction

## Slide 4: OIDC Overview
- OIDC
- What is OIDC?
- OIDC is a simple identity layer built on top of the OAuth2 authorization framework. It provides a standard way to authenticate users and obtain profile information through JSON Web Tokens (JWTs).
- OIDC is the preferred authentication protocol for SaaS applications, APIs, and modern mobile or single-page applications (SPAs), supporting Single Sign-On (SSO) and delegated authorization.
- It enables secure user authentication with minimal friction, supports scopes for fine-grained access control, issues interoperable JWT tokens, and simplifies integration across diverse web and mobile platforms.
- OpenID Connect (OIDC) Defined
- Role in Modern Applications
- Key Benefits of OIDC
- Tailor the examples of modern apps using OIDC to your organization's technology stack for better audience engagement.
- 01
- 02
- 03

## Slide 5: LDAP Overview
- LDAP
- What is LDAP?
- LDAP (Lightweight Directory Access Protocol) is a mature, widely used protocol for accessing and maintaining distributed directory information services, especially in legacy and enterprise environments.
- Commonly used for authenticating legacy applications, POSIX/Linux system logins, and network devices that rely on directory-based user and group information.
- LDAP is essential if you have legacy apps that require LDAP bind authentication, need Unix/Linux group-based access controls, or must interoperate with existing enterprise directories like Active Directory.
- Legacy Directory Protocol
- Use Cases for LDAP
- When LDAP Support is Useful
- Customize this slide by adding examples of legacy applications or network equipment specific to your organization's environment to increase relevance for the engineering team.
- 01
- 02
- 03

## Slide 6: OIDC Value
- Why Use OIDC?
- OIDC is built on OAuth2, enabling secure delegated authorization and authentication for modern web and mobile apps.
Supports JSON Web Tokens (JWTs) for compact, self-contained identity tokens that are easy to validate and pass between services.
Enables single sign-on (SSO) across diverse SaaS applications and APIs with standardized scopes and claims.
Designed for cloud-native, multi-tenant environments, making it scalable and adaptable to complex identity needs.
Widely supported and expected by modern front-end frameworks, mobile apps, and APIs, ensuring interoperability and future-proofing.
- OIDC

## Slide 7: When to Add LDAP
- When to Add LDAP?
- You have legacy applications that only support LDAP bind authentication or expect POSIX groups for access control.
You need to support UNIX/Linux authentication via PAM or SSH against directory groups with MFA integration.
Your environment requires interoperability with customer or partner Active Directory (AD) or LDAP directories without forcing modernization.
You must maintain support for legacy network devices or infrastructure components that rely on LDAP for user authentication.
LDAP enables bridging between traditional enterprise identity systems and modern OIDC-based services ensuring smoother migration paths.
- Highlight specific legacy systems or Linux PAM/SSH use cases in your organization to justify LDAP inclusion.
- LDAP

## Slide 8: OIDC + LDAP Integration
- Integration
- Benefits of Adding LDAP to OIDC
- Adding LDAP allows legacy applications that rely on LDAP bind authentication to continue functioning seamlessly while newer applications use OIDC/OAuth2, enabling coexistence and gradual modernization.
- Keycloak acts as a centralized identity provider that federates or syncs with external LDAP directories and exposes LDAP views, providing a unified identity source across modern and legacy clients.
- Bridge Old and New Systems
- Centralized Identity Management
- A single policy framework in Keycloak governs both OIDC tokens and LDAP groups/attributes, reducing complexity and ensuring consistent access control across diverse authentication methods.
- Implementing LDAP alongside OIDC requires synchronization mechanisms such as SCIM or LDAP sync, schema mapping for attribute consistency, and a globally replicated database to support multi-tenant scale.
- Simplified Policy Enforcement
- Operational Considerations

## Slide 9: Reference Architecture
- IDaaS Reference Architecture Overview
- Keycloak is the core multi-tenant Identity Provider managing realms, users, and authentication.
Cloudflare Zero Trust provides global edge security, access control, and zero-trust network access (ZTNA).
YugabyteDB serves as a globally replicated SQL database for identities, sessions, and consent data.
OIDC handles modern app authentication with SSO, JWT tokens, and delegated authorization.
LDAP supports legacy apps and UNIX auth via Keycloak federation or LDAP storage provider.
- Add specific examples of your organization's regional deployments and identity protocols to make the architecture more relatable to your engineering team.
- Architecture

## Slide 10: Architecture Diagram
- Architecture
- IDaaS Architecture Diagram
- Global Edge & Multi-Region Kubernetes
- Cloudflare Zero Trust provides global edge security and Anycast DNS/LB routes traffic to regional Kubernetes clusters running Keycloak for tenant-scoped identity management and API gateways for ingress.
- Core Services & Directory Integration
- Keycloak clusters connect to a globally replicated YugabyteDB for identity data, integrate with LDAP for legacy directory support, and use SCIM for provisioning to SaaS apps, secured with HSM-backed keys and fine-grained authorization.
- Use this slide to visually explain the comprehensive IDaaS architecture, emphasizing the integration of modern identity protocols and legacy directory support across global infrastructure.

## Slide 11: OIDC and SAML Paths
- OIDC and SAML Authentication Path
- OIDC Authentication Flow
- Modern web, mobile, and SPA apps use OpenID Connect (OIDC) for single sign-on (SSO).
Clients redirect users to Keycloak for authentication within tenant-specific realms.
Keycloak issues JWT tokens (ID, Access, Refresh) after successful login and MFA.
API gateways validate tokens before granting app access, enforcing scopes and claims.
Cloudflare Zero Trust enforces access policies and device posture before allowing entry.
- SAML Authentication Flow
- Legacy or enterprise applications often use SAML for federated authentication.
SAML requests are routed to Keycloak through API gateways acting as service providers.
Keycloak acts as Identity Provider (IdP), authenticates users and issues SAML assertions.
App gateways validate SAML assertions to establish user sessions securely.
Cloudflare Zero Trust integrates with SAML flows to enforce security and access policies.
- Customize this slide by adding specific examples of applications or services your team will integrate using OIDC or SAML to make it more relevant.
- Authentication

## Slide 12: ZTNA Access Model
- ZTNA Access Model
- Cloudflare Access Role
- Enforces user identity and device posture policies before granting access.
Replaces traditional VPN with identity-aware, zero-trust network access.
Integrates WAF and DDoS protection at the global edge for secure access.
Routes traffic through Cloudflare’s global Anycast network for performance and reliability.
- Keycloak as Identity Provider
- Provides tenant-specific realms for multi-tenant identity management.
Handles authentication with OIDC, supporting MFA and WebAuthn.
Issues tokens that represent user identity and access rights.
Enables seamless integration with Cloudflare Access for policy enforcement.
- Customize this slide by highlighting specific device posture checks your organization enforces through Cloudflare Access for enhanced security.
- ZTNA
- 01
- 02

## Slide 13: LDAP Integration
- Integration
- LDAP Integration in IDaaS
- Legacy applications and infrastructure use LDAP bind authentication for user access, relying on directory protocols to validate credentials and retrieve group memberships, essential for POSIX/Linux logins and traditional enterprise apps.
- Keycloak acts as both an LDAP federation source, syncing identities from external LDAP or Active Directory, and as an LDAP storage provider, exposing its user and group data to legacy clients through LDAP protocol.
- For multi-tenant environments, LDAP directory trees can be segmented per tenant using distinct organizational units (OUs), allowing tenant isolation and tailored access controls within a shared LDAP infrastructure.
- Legacy Apps & LDAP Bind
- Keycloak’s LDAP Roles
- Multi-Tenancy with LDAP Trees

## Slide 14: SCIM Provisioning
- SCIM Provisioning Role
- SCIM (System for Cross-domain Identity Management) standardizes identity provisioning and updates across multiple platforms.
It automates user account creation, modification, and deactivation in downstream SaaS and internal applications.
SCIM ensures roles, groups, and user attributes are consistently synchronized, reducing manual errors and administrative overhead.
By integrating SCIM with Keycloak, identity changes propagate seamlessly, maintaining up-to-date access controls across services.
SCIM supports multi-tenant environments by handling provisioning per tenant, enabling scalable user management in IDaaS.
- Provisioning

## Slide 15: Security Components
- Security Components in IDaaS
- WebAuthn and MFA provide phishing-resistant, passwordless or multi-factor authentication to enhance user security.
JWKS (JSON Web Key Sets) enable secure token signing and verification, ensuring integrity and trust in OIDC tokens.
Keys for signing and encryption are securely stored and managed using Hardware Security Modules (HSM) or Key Management Services (KMS) with automated key rotation.
Fine-grained authorization is enforced using Keycloak’s policy engine combined with external tools like OPA or ORY Keto for complex access control scenarios.
Mutual TLS (mTLS) and internal Certificate Authorities (CAs) safeguard service-to-service communication within the IDaaS ecosystem.
- Security

## Slide 16: Observability
- Observability and Audit Trail
- Use OpenTelemetry (OTEL) to collect telemetry data (logs, metrics, traces) from Keycloak clusters, SCIM sync service, and ZTNA components.
Aggregate and store logs centrally using Loki or an EFK (Elasticsearch, Fluentd, Kibana) stack for efficient query and analysis.
Integrate observability data into SIEM (Security Information and Event Management) systems for real-time alerting and incident response.
Maintain detailed audit trails for OIDC authentication events, administrative actions, and Cloudflare Zero Trust access logs to ensure compliance and forensic capabilities.
Leverage observability data to monitor system health, detect anomalies, and support security investigations and compliance audits.
- Include specific examples of observability tools and configurations your team uses or plans to use for better contextual relevance.
- Observability

## Slide 17: Login Flow
- Login Flow
- Login & Access Flow Diagram
- Login & Access Sequence
- Users request access to an app via Cloudflare Zero Trust, are redirected to Keycloak for tenant-specific OIDC authentication with MFA, receive tokens, and then access the app with identity-aware ZTNA enforcement.
- Key Components in Flow
- Key components include the User Browser/Device, Cloudflare Zero Trust gateway, Regional API Gateway, Keycloak identity provider, YugabyteDB global database, and the Private App endpoint enforcing access policies.
- Use this slide to visually explain the secure authentication and authorization flow to engineering teams for clarity on OIDC and ZTNA integration.

## Slide 18: Login Flow Detail
- Login & Access Flow Explained
- Use this slide to clearly explain each phase of the login and access process, emphasizing security checks and token handling relevant to your engineering team.
- Login Flow
- 01
- 02
- 03
- 04
- 05
- The user initiates access by requesting the application URL, typically through a browser or device.
- User Request
- User request logs
Initial access timestamp
Request metadata (IP, device)
- Cloudflare Zero Trust intercepts the request, enforcing WAF rules and access posture checks before forwarding to the regional API gateway.
- Cloudflare Zero Trust Checks
- The API gateway redirects the user to Keycloak for OIDC authentication, including tenant realm discovery to ensure proper multi-tenancy.
- The user completes login by providing credentials and passing MFA/WebAuthn challenges for strong authentication.
- OIDC Authentication Redirect
- User Login and MFA
- WAF event logs
Access posture evaluation reports
Forwarded request to API gateway
- OIDC authentication request
Tenant realm identification
Redirect URL to Keycloak login
- Successful login events
MFA challenge logs
User session initialization
- Keycloak verifies user identity via YugabyteDB, resolves roles and consents, then issues OIDC ID, access, and refresh tokens to the user.
- Token Issuance and Validation
- OIDC tokens issued
User role and consent data
Session state saved in global DB
- User presents access tokens to Cloudflare, which enforces identity and device posture policies, then connects to the private app with optional token introspection by the app.
- Identity-Aware Access to App
- Access token validation logs
ZTNA connection events
Authorized app content delivery
- 06

## Slide 19: OIDC Guidance
- OIDC is the essential identity protocol for modern applications, APIs, and mobile environments.
- Tailor examples to your engineering team's current app stack to highlight OIDC benefits in your environment.
- Practical Guidance
- OIDC enables seamless SSO, standardized token-based auth, and broad compatibility with cloud-native & SaaS ecosystems. It simplifies integration, boosts security with JWTs & scopes, and supports delegated authorization, making it key for any IDaaS solution.

## Slide 20: LDAP Guidance
- Legacy Applications
- Linux PAM and SSH
- Customer AD Interoperability
- Guidance
- Practical Guidance: When to Add LDAP
- Include LDAP when you have legacy apps that only support LDAP bind authentication or expect POSIX group membership for access control.
- Use LDAP to enable Linux PAM and SSH authentication against directory groups, supporting MFA via SSH CA or PAM modules for secure access.
- Add LDAP support to federate or synchronize with external customer Active Directory/LDAP without forcing immediate modernization.
- Customize by highlighting specific legacy apps or environments your team supports that mandate LDAP integration.

## Slide 21: Tenant Isolation Strategy
- Tenant Isolation
- Tenant Isolation Strategy
- Each tenant is assigned a dedicated Keycloak realm, providing strong domain isolation, independent authentication policies, and client configurations for secure multi-tenancy.
- Optionally, separate LDAP directory trees (organizational units) per tenant allow legacy systems and bind-auth clients to integrate securely without cross-tenant data exposure.
- Tenant-specific data, including identities, sessions, and consents, are partitioned at the database level using tenant IDs to ensure data segregation and global consistency.
- Keycloak Realms per Tenant
- Per-Tenant LDAP Trees
- YugabyteDB Tenant Data Partitioning
- Customize this slide by adding examples of tenant-specific policies or schema structures relevant to your organization.

## Slide 22: Realm and LDAP Trees
- Keycloak Realm and LDAP Trees
- Keycloak Realms and Tenant Isolation
- Each tenant is assigned a dedicated Keycloak realm ensuring strict data and policy isolation.
Realms encapsulate tenant-specific users, clients, roles, and authentication flows.
Tenant-specific OIDC/SAML clients and policies live within their respective realms.
Realms act as the authoritative identity boundary for tenant operations and management.
- Tenant LDAP Trees and Synchronization
- Each tenant can have a distinct LDAP directory tree (e.g., ou=tenantX,dc=idaas,dc=local) to support legacy integrations.
Keycloak uses LDAP storage providers configured as read-mostly for global consistency and conflict avoidance.
Synchronization jobs keep LDAP directories updated from Keycloak realms, minimizing write contention across regions.
This approach bridges modern OIDC identity with legacy LDAP clients while maintaining operational scalability.
- Tenant Isolation
- 01
- 02

## Slide 23: Security Best Practices
- Security
- Security Best Practices
- Customize this slide with your organization’s specific security tools and policies to make it actionable for your team.
- Hardware-Backed Key Storage
- Use KMS or HSM to securely store cryptographic keys for token signing and encryption, ensuring keys are protected from unauthorized access and easy to rotate.
- Regularly rotate JSON Web Key Sets (JWKS) used for signing tokens to reduce the risk of key compromise and maintain trust across distributed systems.
- JWKS Key Rotation
- Adopt WebAuthn as the default multi-factor authentication method to provide phishing-resistant strong authentication for users accessing IDaaS.
- Place Cloudflare Access in front of admin consoles and private development tools to enforce identity and device posture for comprehensive access control.
- Enforce WebAuthn MFA
- Secure Admin & Private Tools

## Slide 24: Observability Stack
- Observability
- Observability Implementation
- OTEL collects distributed tracing, metrics, and logs from Keycloak, SCIM, and other IDaaS components to provide unified observability across the system.
- Logs from Keycloak, SCIM sync service, and connectors are aggregated with Loki and the EFK stack (Elasticsearch, Fluentd, Kibana) for powerful search, visualization, and alerting.
- Audit logs capture OIDC authentication events, admin actions, and ZTNA access logs, ensuring traceability and compliance with security policies and regulations.
- OpenTelemetry (OTEL) Integration
- Loki/EFK Logging Stack
- Audit Trails and Compliance
- Customize the observability stack details to reflect your team's existing tools and compliance requirements for the most relevant implementation guidance.

## Slide 25: CI/CD Overview
- CI/CD and Deployment Overview
- GitLab CI automates build, test, package, and deploy stages for IDaaS components.
Helm charts manage Kubernetes deployments, enabling easy configuration and upgrades.
Multiple environments supported: review apps for feature branches, staging, and production.
Use Docker-in-Docker (DinD) for building container images within the pipeline.
Deployment targets Rancher-managed multi-region Kubernetes clusters.
- Deployment

## Slide 26: Pipeline Details
- Minimal .gitlab-ci.yml Pipeline Overview
- Pipeline Stages and Jobs
- .gitlab-ci.yml Example
- Pipeline includes lint, build, package, and deploy stages for IDaaS components.
Lint stage validates Helm charts to catch configuration issues early.
Build stage compiles and pushes container images like the SCIM sync service.
Deploy stage uses Helm to install or upgrade components in Kubernetes clusters.
- Adapt the pipeline by adding extra testing or environment-specific deploy rules to fit your project needs.
- CI/CD

## Slide 27: Repository Structure
- Implementation
- Repository Structure for IDaaS
- Customize this slide by adding specific tooling or process notes relevant to your engineering team's existing workflows or technologies.
- Contains infrastructure-as-code such as Terraform scripts for cluster provisioning, DNS setup, and Cloudflare configuration to automate and manage the foundational platform components.
- Holds Helm charts for deploying core IDaaS components like Keycloak, YugabyteDB, OpenLDAP/FreeIPA, SCIM sync services, observability stacks, and Cloudflare Access connectors.
- /infra/ Directory
- /charts/ Directory
- Includes source code and Dockerfiles for application-level services such as the SCIM synchronization service, enabling containerized deployment and version control.
- Stores JSON or ZIP Keycloak realm templates, client configurations, role definitions, and policy files to enable multi-tenant realm management and automated realm provisioning.
- /apps/ Directory
- /keycloak/ Directory
- Contains operational assets like Cloudflare Access policy YAMLs, runbooks for SREs, threat models, audit configurations, and scripts for backup, restore, and key rotation procedures.
- /ops/ Directory

## Slide 28: OIDC + LDAP Summary
- Summary
- Summary: Why OIDC + LDAP?
- OIDC is the standard for cloud-native, web and mobile apps, enabling secure SSO, JWTs, and delegated access. It provides a scalable, multi-tenant identity layer essential for modern IDaaS implementations.
- LDAP remains critical for legacy enterprise apps, POSIX/Linux authentication, and network device integrations. It bridges older systems with modern IDaaS, ensuring continuity without forcing immediate modernization.
- Using OIDC alongside LDAP allows organizations to centralize identity management, maintain policy consistency, and provide seamless access across diverse app ecosystems. This hybrid model supports gradual migration and operational flexibility.
- OIDC for Modern Identity
- LDAP for Legacy Support
- Combined Approach Benefits
- Tailor the examples in each section to reflect your organization's specific legacy systems and modern app landscape for maximum relevance.

## Slide 29: Implementation Next Steps
- Next Steps for Implementation
- Define project scope and tenant requirements to tailor IDaaS components.
Set up Kubernetes clusters with Rancher for multi-region deployment.
Customize and configure Helm charts for Keycloak, OpenLDAP, SCIM sync service, and YugabyteDB.
Implement CI/CD pipelines with GitLab for automated linting, building, packaging, and deployment.
Conduct integration testing with modern and legacy apps to verify OIDC and LDAP workflows.
- Implementation

