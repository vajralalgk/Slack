# ECTP Security Policy

**Author:** Gopi Krishna Vajrala
**Version:** 1.0.0
**Classification:** Internal - Confidential

---

## 1. Access Control

- **Authentication:** AWS Cognito with SAML 2.0 federation + MFA
- **Authorization:** RBAC with least-privilege IAM policies
- **Password Policy:** 14+ characters, complexity required, 90-day rotation
- **Service Accounts:** IAM roles only (no long-lived access keys)
- **Access Reviews:** Quarterly certification of all permissions

## 2. Encryption

- **At Rest:** AES-256 via AWS KMS (Customer Managed Keys)
- **In Transit:** TLS 1.3 (minimum TLS 1.2)
- **Key Rotation:** Automatic annual rotation via KMS
- **Field-Level:** PII fields encrypted at application layer
- **Secrets:** AWS Secrets Manager with automatic rotation

## 3. Network Security

- **VPC Isolation:** All resources in private subnets
- **Security Groups:** Deny-all default, explicit allow rules
- **NACLs:** Additional subnet-level filtering
- **WAF:** AWS WAF on all public-facing endpoints
- **DDoS Protection:** AWS Shield Advanced
- **VPN:** Site-to-site VPN for on-premises connectivity

## 4. Vulnerability Management

- **SAST:** Bandit + Semgrep in CI/CD pipeline (every PR)
- **DAST:** OWASP ZAP weekly scans
- **Dependency Scanning:** Dependabot + Safety (daily)
- **Infrastructure Scanning:** AWS Inspector (continuous)
- **Container Scanning:** ECR image scanning (every push)
- **Penetration Testing:** External firm, quarterly

## 5. Incident Response

| Severity | Response Time | Escalation | Communication |
|----------|-------------|-----------|---------------|
| Critical | 15 minutes | CIO within 1 hour | Stakeholder notification |
| High | 30 minutes | IT Director within 2 hours | Team notification |
| Medium | 4 hours | Manager within 24 hours | Email update |
| Low | Next business day | Normal process | Ticket update |

## 6. Data Classification

| Level | Description | Controls |
|-------|------------|----------|
| Public | Marketing, general info | Standard encryption |
| Internal | Operational data | Authentication required |
| Confidential | Student PII, financial | RBAC + MFA + audit logging |
| Restricted | SSN, health records | MFA + field encryption + DLP |

## 7. Compliance

### FERPA (Student Data)
- Access controls with audit logging
- Data minimization (only access needed fields)
- Breach notification within 72 hours
- Annual training for all staff accessing student data

### HIPAA (Health Data)
- Business Associate Agreements with all vendors
- Encryption at rest and in transit
- Access logging and monitoring
- Minimum necessary access standard

### SOC 2
- Security, availability, processing integrity controls
- Continuous monitoring and evidence collection
- Annual audit by external firm
- Automated compliance reporting

---

**Author:** Gopi Krishna Vajrala
