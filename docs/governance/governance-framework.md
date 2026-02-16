# ECTP Governance Framework

**Author:** Gopi Krishna Vajrala
**Version:** 1.0.0
**Date:** 2026-02-16

---

## 1. Governance Structure

```
Executive Steering Committee (Quarterly)
    |
Platform Governance Board (Monthly)
    |
Cloud Center of Excellence - CCoE (Weekly)
    |
    +-- Security Review Board
    +-- Cost Review Board
    +-- Change Advisory Board
```

### Executive Steering Committee
- **Members:** CIO, CFO, VP Academic Affairs, VP Student Services
- **Cadence:** Quarterly
- **Responsibilities:** Strategic direction, budget approval, risk acceptance

### Platform Governance Board
- **Members:** IT Director, Cloud Architect, Security Lead, Compliance Officer
- **Cadence:** Monthly
- **Responsibilities:** Architecture decisions, policy enforcement, roadmap prioritization

### Cloud Center of Excellence (CCoE)
- **Members:** Cloud engineers, developers, SRE team
- **Cadence:** Weekly
- **Responsibilities:** Day-to-day operations, technical decisions, standards enforcement

---

## 2. Change Management

| Change Type | Approval | Lead Time | Risk Assessment |
|------------|----------|-----------|-----------------|
| Standard | Pre-approved | None | Low |
| Normal | Change Board | 5 business days | Medium |
| Emergency | IT Director | Immediate | Post-change review |

### Process
1. Submit change request (ServiceNow)
2. Impact assessment and risk scoring
3. Peer review of implementation plan
4. Approval per change type
5. Implementation during maintenance window
6. Post-implementation validation
7. Close change request with evidence

---

## 3. Cost Governance

- **Budget Ownership:** Department heads own their cost allocation
- **Tagging Enforcement:** All resources must have mandatory tags (automated)
- **Alert Thresholds:** 50%, 80%, 100% of monthly budget
- **Monthly Reviews:** Cost review meeting with department heads
- **Optimization Cadence:** Quarterly right-sizing and RI review
- **Showback Reports:** Monthly reports to department heads

---

## 4. Security Governance

- **Vulnerability Scanning:** Daily automated scans (Inspector, GuardDuty)
- **Penetration Testing:** Quarterly by external firm
- **Access Reviews:** Quarterly IAM access certification
- **Incident Response:** Documented playbooks with < 15 min response for P1
- **Compliance Monitoring:** Continuous via AWS Config and Security Hub
- **Security Training:** Annual for all IT staff, quarterly for developers

---

## 5. Architecture Decision Records (ADR)

All significant architecture decisions must be documented as ADRs:
- **Template:** Located in `/docs/adr/`
- **Process:** Propose → Review → Accept/Reject → Document
- **Review Board:** Platform Governance Board

---

## 6. SLA Governance

| Tier | Availability | RTO | RPO | Review |
|------|-------------|-----|-----|--------|
| Tier 1 (Critical) | 99.95% | 15 min | 0 | Monthly |
| Tier 2 (Important) | 99.9% | 1 hour | 15 min | Monthly |
| Tier 3 (Standard) | 99.5% | 4 hours | 1 hour | Quarterly |
| Tier 4 (Non-Critical) | 99.0% | 24 hours | 24 hours | Quarterly |

---

## 7. Risk Management

- **Risk Register:** Maintained in project documentation
- **Risk Reviews:** Monthly at Governance Board
- **Risk Scoring:** Likelihood x Impact matrix (1-5 scale)
- **Mitigation Tracking:** Assigned owners with due dates
- **Escalation:** Critical risks escalated to Steering Committee

---

**Author:** Gopi Krishna Vajrala
