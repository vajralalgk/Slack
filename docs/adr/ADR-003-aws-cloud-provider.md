# ADR-003: AWS as Primary Cloud Provider

**Author:** Gopi Krishna Vajrala
**Date:** 2026-02-16
**Status:** Accepted

## Context
ECTP requires a cloud provider for all infrastructure, compute, storage, and managed services.

## Decision
Use **Amazon Web Services (AWS)** as the primary cloud provider.

## Rationale
- Market leader with broadest service catalog
- Highest adoption in Higher Education institutions
- FERPA, HIPAA, SOC2, FedRAMP compliance certifications
- Largest partner ecosystem for Higher Ed (Ellucian, ServiceNow)
- Comprehensive security services (GuardDuty, Security Hub, Inspector)
- Mature cost management tools (Cost Explorer, Budgets)
- Strong presence in us-east-1 (closest to many institutions)

## Consequences
- Positive: Broadest service availability, compliance certifications, Higher Ed adoption
- Negative: Risk of vendor lock-in (mitigated by containerization and Terraform abstraction)

## Author
Gopi Krishna Vajrala
