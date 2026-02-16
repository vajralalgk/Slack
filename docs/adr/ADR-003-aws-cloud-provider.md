<div align="center">

# ADR-003: AWS as Primary Cloud Provider

![Status](https://img.shields.io/badge/Status-ACCEPTED-brightgreen?style=for-the-badge)
![Category](https://img.shields.io/badge/Category-Cloud_Provider-blue?style=for-the-badge)
![Priority](https://img.shields.io/badge/Priority-Critical-red?style=for-the-badge)

</div>

---

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║   DECISION SUMMARY                                                         ║
║                                                                            ║
║   Use Amazon Web Services (AWS) as the primary cloud provider for ECTP.    ║
║                                                                            ║
║   AWS is the market leader with the broadest service catalog, highest      ║
║   adoption in Higher Education, comprehensive compliance certifications    ║
║   (FERPA, HIPAA, SOC2, FedRAMP), and the largest partner ecosystem for     ║
║   Higher Ed integrations.                                                  ║
║                                                                            ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

---

## Document Metadata

| Field | Details |
|:---|:---|
| **ADR Number** | ADR-003 |
| **Title** | AWS as Primary Cloud Provider |
| **Author** | Gopi Krishna Vajrala |
| **Date** | 2026-02-16 |
| **Status** | ![ACCEPTED](https://img.shields.io/badge/ACCEPTED-brightgreen?style=flat-square) |
| **Reviewers** | Platform Architecture Team |
| **Category** | Cloud Provider Selection |
| **Supersedes** | N/A |

---

## Context

### Problem Statement

```
┌──────────────────────────────────────────────────────────────────────────┐
│                                                                          │
│   ECTP requires a cloud provider that delivers:                          │
│                                                                          │
│     * Enterprise-grade infrastructure for compute, storage, and          │
│       managed services                                                   │
│     * Compliance certifications for Higher Education (FERPA, HIPAA)      │
│     * Robust security services and governance tools                      │
│     * Strong ecosystem of Higher Ed technology partners                  │
│     * Cost management and optimization capabilities                      │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

ECTP requires a cloud provider for all infrastructure, compute, storage, and managed services.

---

## Decision

> **We will use Amazon Web Services (AWS) as the primary cloud provider for ECTP.**

```
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║                  >>> Amazon Web Services (AWS) <<<                    ║
║                                                                      ║
║          The world's most comprehensive and broadly adopted           ║
║          cloud platform, offering over 200 fully featured             ║
║          services from data centers globally.                         ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
```

---

## Rationale

### Key Decision Drivers

| # | Factor | Details | Importance |
|:---:|:---|:---|:---:|
| 1 | **Market Leadership** | Broadest service catalog of any cloud provider | ![CRITICAL](https://img.shields.io/badge/CRITICAL-red?style=flat-square) |
| 2 | **Higher Ed Adoption** | Highest adoption rate among Higher Education institutions | ![CRITICAL](https://img.shields.io/badge/CRITICAL-red?style=flat-square) |
| 3 | **Compliance** | FERPA, HIPAA, SOC2, FedRAMP compliance certifications | ![CRITICAL](https://img.shields.io/badge/CRITICAL-red?style=flat-square) |
| 4 | **Partner Ecosystem** | Largest partner ecosystem for Higher Ed (Ellucian, ServiceNow) | ![HIGH](https://img.shields.io/badge/HIGH-brightgreen?style=flat-square) |
| 5 | **Security Services** | Comprehensive suite: GuardDuty, Security Hub, Inspector | ![HIGH](https://img.shields.io/badge/HIGH-brightgreen?style=flat-square) |
| 6 | **Cost Management** | Mature tools: Cost Explorer, Budgets, Savings Plans | ![MEDIUM](https://img.shields.io/badge/MEDIUM-green?style=flat-square) |
| 7 | **Regional Presence** | Strong presence in us-east-1 (closest to many institutions) | ![MEDIUM](https://img.shields.io/badge/MEDIUM-green?style=flat-square) |

### Compliance Certifications

```
  ┌─────────────────────────────────────────────────────────────────────┐
  │                   AWS Compliance Coverage                           │
  ├─────────────────────────────────────────────────────────────────────┤
  │                                                                     │
  │   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
  │   │  FERPA   │  │  HIPAA   │  │  SOC2    │  │    FedRAMP       │  │
  │   │          │  │          │  │          │  │                  │  │
  │   │ Student  │  │ Health   │  │ Security │  │   Federal Gov    │  │
  │   │ Privacy  │  │ Data     │  │ Controls │  │   Standard       │  │
  │   └──────────┘  └──────────┘  └──────────┘  └──────────────────┘  │
  │                                                                     │
  │           All certifications verified and maintained                │
  └─────────────────────────────────────────────────────────────────────┘
```

### Security Services Ecosystem

```
  AWS Security Services for ECTP

  ┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
  │   GuardDuty      │   │  Security Hub    │   │   Inspector      │
  │                  │   │                  │   │                  │
  │  Threat          │   │  Centralized     │   │  Vulnerability   │
  │  Detection       │   │  Security View   │   │  Assessment      │
  │  & Monitoring    │   │  & Compliance    │   │  & Scanning      │
  └──────────────────┘   └──────────────────┘   └──────────────────┘
           │                      │                      │
           └──────────────────────┼──────────────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │    Unified Security        │
                    │    Posture Management      │
                    └───────────────────────────┘
```

---

## Alternatives Considered

### Cloud Provider Comparison

| Criteria | AWS | Azure | GCP |
|:---|:---:|:---:|:---:|
| **Service Breadth** | 200+ services | 200+ services | 100+ services |
| **Higher Ed Adoption** | Highest | Growing | Limited |
| **FERPA Compliance** | Yes | Yes | Yes |
| **HIPAA Compliance** | Yes | Yes | Yes |
| **FedRAMP** | Yes | Yes | Yes |
| **Higher Ed Partners** | Ellucian, ServiceNow | Limited | Limited |
| **Cost Management** | Mature | Mature | Good |
| **us-east-1 Presence** | Strong | Strong | Moderate |

### Scoring Summary

| Criteria | Weight | AWS | Azure | GCP |
|:---|:---:|:---:|:---:|:---:|
| Service Breadth | 20% | ![10/10](https://img.shields.io/badge/10%2F10-brightgreen?style=flat-square) | ![9/10](https://img.shields.io/badge/9%2F10-brightgreen?style=flat-square) | ![7/10](https://img.shields.io/badge/7%2F10-yellowgreen?style=flat-square) |
| Higher Ed Adoption | 25% | ![10/10](https://img.shields.io/badge/10%2F10-brightgreen?style=flat-square) | ![6/10](https://img.shields.io/badge/6%2F10-yellow?style=flat-square) | ![4/10](https://img.shields.io/badge/4%2F10-orange?style=flat-square) |
| Compliance | 20% | ![10/10](https://img.shields.io/badge/10%2F10-brightgreen?style=flat-square) | ![9/10](https://img.shields.io/badge/9%2F10-brightgreen?style=flat-square) | ![8/10](https://img.shields.io/badge/8%2F10-green?style=flat-square) |
| Partner Ecosystem | 20% | ![10/10](https://img.shields.io/badge/10%2F10-brightgreen?style=flat-square) | ![5/10](https://img.shields.io/badge/5%2F10-yellow?style=flat-square) | ![4/10](https://img.shields.io/badge/4%2F10-orange?style=flat-square) |
| Cost Management | 15% | ![9/10](https://img.shields.io/badge/9%2F10-brightgreen?style=flat-square) | ![9/10](https://img.shields.io/badge/9%2F10-brightgreen?style=flat-square) | ![8/10](https://img.shields.io/badge/8%2F10-green?style=flat-square) |
| **Weighted Total** | **100%** | **![9.8](https://img.shields.io/badge/9.8%2F10-brightgreen?style=flat-square)** | **![7.3](https://img.shields.io/badge/7.3%2F10-yellowgreen?style=flat-square)** | **![5.9](https://img.shields.io/badge/5.9%2F10-yellow?style=flat-square)** |

---

## Consequences

### Positive Outcomes

| # | Consequence | Impact |
|:---:|:---|:---:|
| 1 | Broadest service availability enabling any future architecture choice | ![HIGH](https://img.shields.io/badge/HIGH-brightgreen?style=flat-square) |
| 2 | Full compliance certifications (FERPA, HIPAA, SOC2, FedRAMP) | ![HIGH](https://img.shields.io/badge/HIGH-brightgreen?style=flat-square) |
| 3 | Highest Higher Ed adoption ensures community support and best practices | ![HIGH](https://img.shields.io/badge/HIGH-brightgreen?style=flat-square) |
| 4 | Largest partner ecosystem for Ellucian and ServiceNow integrations | ![HIGH](https://img.shields.io/badge/HIGH-brightgreen?style=flat-square) |
| 5 | Comprehensive security services for enterprise governance | ![MEDIUM](https://img.shields.io/badge/MEDIUM-green?style=flat-square) |
| 6 | Mature cost management tools for budget governance | ![MEDIUM](https://img.shields.io/badge/MEDIUM-green?style=flat-square) |

### Risks & Mitigations

| # | Risk | Severity | Mitigation |
|:---:|:---|:---:|:---|
| 1 | Risk of vendor lock-in with AWS-specific services | ![MEDIUM](https://img.shields.io/badge/MEDIUM-orange?style=flat-square) | Containerization (ECS/EKS) and Terraform abstraction layer ensure portability |

---

## References

| Resource | Link |
|:---|:---|
| AWS Cloud for Higher Education | [https://aws.amazon.com/education/higher-ed/](https://aws.amazon.com/education/higher-ed/) |
| AWS Compliance Programs | [https://aws.amazon.com/compliance/programs/](https://aws.amazon.com/compliance/programs/) |
| AWS Security Services | [https://aws.amazon.com/products/security/](https://aws.amazon.com/products/security/) |
| ECTP Architecture Document | [Architecture Document](../architecture/architecture-document.md) |

---

<div align="center">

**Author:** Gopi Krishna Vajrala

*Architecture Decision Record -- ECTP Platform*

</div>
