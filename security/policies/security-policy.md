<div align="center">

```
╔══════════════════════════════════════════════════════════════════════════╗
║                                                                        ║
║                        *** CONFIDENTIAL ***                            ║
║                                                                        ║
║              ECTP SECURITY POLICY - INTERNAL USE ONLY                  ║
║                                                                        ║
║     Unauthorized access, distribution, or reproduction prohibited.     ║
║                                                                        ║
╚══════════════════════════════════════════════════════════════════════════╝
```

# ECTP Security Policy

**Author:** Gopi Krishna Vajrala
**Version:** 1.0.0
**Classification:** `CONFIDENTIAL` - Internal Use Only
**Last Updated:** 2026-02-16

</div>

---

## Security Architecture Overview

```
ECTP DEFENSE-IN-DEPTH SECURITY LAYERS
══════════════════════════════════════════════════════════════════════

  ┌──────────────────────────────────────────────────────────────┐
  │                    LAYER 1: PERIMETER                       │
  │           AWS WAF  |  AWS Shield Advanced  |  DDoS          │
  ├──────────────────────────────────────────────────────────────┤
  │                    LAYER 2: NETWORK                         │
  │       VPC Isolation  |  Security Groups  |  NACLs  |  VPN   │
  ├──────────────────────────────────────────────────────────────┤
  │                    LAYER 3: IDENTITY                        │
  │     Cognito + SAML 2.0  |  MFA  |  RBAC  |  IAM Roles      │
  ├──────────────────────────────────────────────────────────────┤
  │                    LAYER 4: APPLICATION                     │
  │       Input Validation  |  SAST/DAST  |  Dependency Scan    │
  ├──────────────────────────────────────────────────────────────┤
  │                    LAYER 5: DATA                            │
  │    AES-256 at Rest  |  TLS 1.3 in Transit  |  Field-Level   │
  ├──────────────────────────────────────────────────────────────┤
  │                    LAYER 6: MONITORING                      │
  │     CloudWatch  |  CloudTrail  |  GuardDuty  |  Inspector   │
  └──────────────────────────────────────────────────────────────┘

══════════════════════════════════════════════════════════════════════
```

---

## :lock: 1. Access Control

> **Principle:** Least privilege access with strong identity verification

| Control | Implementation | Standard |
|---------|---------------|----------|
| **Authentication** | AWS Cognito with SAML 2.0 federation + MFA | NIST 800-63B |
| **Authorization** | RBAC with least-privilege IAM policies | NIST 800-53 AC |
| **Password Policy** | 14+ characters, complexity required, 90-day rotation | NIST 800-63B |
| **Service Accounts** | IAM roles only (no long-lived access keys) | AWS Best Practice |
| **Access Reviews** | Quarterly certification of all permissions | SOC 2 |

```
ACCESS CONTROL FLOW
══════════════════════════════════════════════════════════════

  User Request
       │
       ▼
  ┌──────────┐     ┌──────────┐     ┌──────────┐
  │  Cognito  │────►│   MFA    │────►│   RBAC   │───► Access Granted
  │  + SAML   │     │  Verify  │     │  Check   │    or Denied
  └──────────┘     └──────────┘     └──────────┘
       │                                   │
       ▼                                   ▼
  Identity Pool                     IAM Policy
  Federation                       Evaluation

══════════════════════════════════════════════════════════════
```

---

## :key: 2. Encryption

> **Principle:** Encrypt everything, everywhere, always

| Layer | Standard | Technology | Key Management |
|-------|----------|------------|----------------|
| **At Rest** | AES-256 | AWS KMS (Customer Managed Keys) | Automatic annual rotation |
| **In Transit** | TLS 1.3 (min TLS 1.2) | AWS Certificate Manager | Managed certificates |
| **Key Rotation** | Annual | AWS KMS automatic rotation | Automated via KMS |
| **Field-Level** | AES-256 | Application-layer encryption | Per-field CMK |
| **Secrets** | AES-256 | AWS Secrets Manager | Automatic rotation |

```
ENCRYPTION AT EVERY LAYER
══════════════════════════════════════════════════════════

  Client ──── TLS 1.3 ────► ALB ──── TLS 1.3 ────► ECS
                                                      │
                                            Field-Level Encryption
                                                      │
                                                      ▼
                                              ┌───────────────┐
                                              │   RDS (AES-256)│
                                              │   KMS-CMK     │
                                              └───────────────┘

══════════════════════════════════════════════════════════
```

---

## :shield: 3. Network Security

> **Principle:** Zero-trust network with defense in depth

| Control | Description | Layer |
|---------|-------------|-------|
| **VPC Isolation** | All resources in private subnets | Network |
| **Security Groups** | Deny-all default, explicit allow rules | Instance |
| **NACLs** | Additional subnet-level filtering | Subnet |
| **WAF** | AWS WAF on all public-facing endpoints | Edge |
| **DDoS Protection** | AWS Shield Advanced | Edge |
| **VPN** | Site-to-site VPN for on-premises connectivity | Network |

```
NETWORK SECURITY ARCHITECTURE
══════════════════════════════════════════════════════════════════

  Internet
     │
     ▼
  ┌─────────────────────────────────────────────────────┐
  │  AWS Shield Advanced + WAF                          │
  ├─────────────────────────────────────────────────────┤
  │  Public Subnet (ALB only)                           │
  │  ┌───────────┐                                      │
  │  │    ALB    │                                      │
  │  └─────┬─────┘                                      │
  ├────────┼────────────────────────────────────────────┤
  │  Private Subnet (Application)         NACLs + SGs   │
  │  ┌─────▼─────┐                                      │
  │  │  ECS Tasks │                                     │
  │  └─────┬─────┘                                      │
  ├────────┼────────────────────────────────────────────┤
  │  Private Subnet (Data)                NACLs + SGs   │
  │  ┌─────▼─────┐  ┌───────────┐                      │
  │  │    RDS    │  │ ElastiCache│                      │
  │  └───────────┘  └───────────┘                      │
  └─────────────────────────────────────────────────────┘
       │
       │ Site-to-Site VPN
       ▼
  On-Premises Network

══════════════════════════════════════════════════════════════════
```

---

## :mag: 4. Vulnerability Management

> **Principle:** Continuous scanning at every stage of the pipeline

| Scan Type | Tool | Frequency | Stage | Coverage |
|-----------|------|-----------|-------|----------|
| **SAST** | Bandit + Semgrep | Every PR | CI/CD Pipeline | :white_check_mark: Code |
| **DAST** | OWASP ZAP | Weekly | Post-deployment | :white_check_mark: Runtime |
| **Dependency Scanning** | Dependabot + Safety | Daily | CI/CD Pipeline | :white_check_mark: Libraries |
| **Infrastructure Scanning** | AWS Inspector | Continuous | Runtime | :white_check_mark: Infrastructure |
| **Container Scanning** | ECR image scanning | Every push | CI/CD Pipeline | :white_check_mark: Containers |
| **Penetration Testing** | External firm | Quarterly | All layers | :white_check_mark: Full Stack |

```
VULNERABILITY SCANNING PIPELINE
══════════════════════════════════════════════════════════════

  Code Commit
       │
       ▼
  ┌──────────┐   ┌──────────────┐   ┌───────────┐
  │   SAST   │──►│  Dependency  │──►│ Container │──► Deploy
  │  Bandit  │   │   Scanning   │   │  Scanning │
  │ Semgrep  │   │ Dependabot   │   │    ECR    │
  └──────────┘   └──────────────┘   └───────────┘

  Post-Deploy
       │
       ▼
  ┌──────────┐   ┌──────────────┐   ┌───────────┐
  │   DAST   │   │  Inspector   │   │  Pen Test │
  │ OWASP ZAP│   │ (Continuous) │   │(Quarterly)│
  └──────────┘   └──────────────┘   └───────────┘

══════════════════════════════════════════════════════════════
```

---

## :rotating_light: 5. Incident Response

> **Principle:** Rapid detection, containment, and recovery

```
INCIDENT RESPONSE SEVERITY TIMELINE
══════════════════════════════════════════════════════════════════════

  CRITICAL   ├──15 min──┤──1 hour──┤ CIO notified, stakeholder comms
  (Red)      Respond     Escalate

  HIGH       ├──30 min──┤──2 hours─┤ IT Director notified, team comms
  (Orange)   Respond     Escalate

  MEDIUM     ├──4 hours─────────────┤──24 hours──┤ Manager notified
  (Yellow)   Respond                  Escalate

  LOW        ├──Next business day────────────────┤ Normal process
  (Blue)     Respond & resolve via ticket

══════════════════════════════════════════════════════════════════════
```

| | Severity | Response Time | Escalation | Communication |
|---|---|---|---|---|
| :red_circle: | **Critical** | **15 minutes** | CIO within 1 hour | Stakeholder notification |
| :orange_circle: | **High** | **30 minutes** | IT Director within 2 hours | Team notification |
| :yellow_circle: | **Medium** | **4 hours** | Manager within 24 hours | Email update |
| :blue_circle: | **Low** | **Next business day** | Normal process | Ticket update |

---

## :file_folder: 6. Data Classification

> **Principle:** Protect data according to its sensitivity level

```
DATA CLASSIFICATION PYRAMID
══════════════════════════════════════════════════════

              ┌─────────┐
              │RESTRICTED│  SSN, health records
              │  (Red)   │  MFA + Field Encryption + DLP
              ├─────────┤
             │CONFIDENTIAL│  Student PII, financial
             │  (Orange)  │  RBAC + MFA + Audit Logging
             ├───────────┤
            │   INTERNAL   │  Operational data
            │   (Yellow)   │  Authentication Required
            ├─────────────┤
           │     PUBLIC      │  Marketing, general info
           │    (Green)      │  Standard Encryption
           └─────────────────┘

══════════════════════════════════════════════════════
```

| | Level | Description | Controls | Examples |
|---|---|---|---|---|
| :red_circle: | **Restricted** | Highest sensitivity | MFA + field encryption + DLP | SSN, health records |
| :orange_circle: | **Confidential** | High sensitivity | RBAC + MFA + audit logging | Student PII, financial data |
| :yellow_circle: | **Internal** | Moderate sensitivity | Authentication required | Operational data |
| :green_circle: | **Public** | Low sensitivity | Standard encryption | Marketing, general info |

---

## :white_check_mark: 7. Compliance

> **Principle:** Continuous compliance with regulatory frameworks

### Compliance Matrix

| | Framework | Scope | Key Requirements | Status |
|---|---|---|---|---|
| :white_check_mark: | **FERPA** | Student Data | Access controls, audit logging, breach notification | `Active` |
| :white_check_mark: | **HIPAA** | Health Data | BAA, encryption, access logging, minimum necessary | `Active` |
| :white_check_mark: | **SOC 2** | All Systems | Security, availability, processing integrity | `Active` |

---

### :mortar_board: FERPA (Student Data)

| Requirement | Implementation | Evidence |
|-------------|---------------|----------|
| Access controls with audit logging | Cognito RBAC + CloudTrail | Audit log reports |
| Data minimization (only access needed fields) | Field-level RBAC policies | Policy documentation |
| Breach notification within 72 hours | Incident response procedure | IR playbook |
| Annual training for all staff accessing student data | LMS training modules | Training records |

---

### :hospital: HIPAA (Health Data)

| Requirement | Implementation | Evidence |
|-------------|---------------|----------|
| Business Associate Agreements with all vendors | Legal-reviewed BAAs | Signed agreements |
| Encryption at rest and in transit | KMS AES-256 + TLS 1.3 | Encryption audit |
| Access logging and monitoring | CloudTrail + CloudWatch | Log retention proof |
| Minimum necessary access standard | Least-privilege IAM | Access reviews |

---

### :mag_right: SOC 2

| Requirement | Implementation | Evidence |
|-------------|---------------|----------|
| Security, availability, processing integrity controls | Multi-layer security architecture | Architecture docs |
| Continuous monitoring and evidence collection | Automated compliance tools | Dashboard reports |
| Annual audit by external firm | Scheduled external audits | Audit reports |
| Automated compliance reporting | AWS Config + Security Hub | Automated reports |

---

<div align="center">

```
╔══════════════════════════════════════════════════════════════════════════╗
║                                                                        ║
║                        *** CONFIDENTIAL ***                            ║
║                                                                        ║
║     This document contains confidential security information.          ║
║     Handle according to ECTP Data Classification Policy.               ║
║                                                                        ║
╚══════════════════════════════════════════════════════════════════════════╝
```

```
══════════════════════════════════════════════════════════════
                   END OF SECURITY POLICY
            Enterprise Cloud Transformation Platform
══════════════════════════════════════════════════════════════
```

**Author:** Gopi Krishna Vajrala

</div>
