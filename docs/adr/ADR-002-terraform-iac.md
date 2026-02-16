# ADR-002: Terraform for Infrastructure as Code

**Author:** Gopi Krishna Vajrala
**Date:** 2026-02-16
**Status:** Accepted

## Context
ECTP infrastructure must be defined as code for repeatability, version control, and multi-environment deployment.

## Decision
Use **Terraform** as the primary IaC tool.

## Rationale
| Criteria | Terraform | CloudFormation | Pulumi | CDK |
|----------|-----------|---------------|--------|-----|
| Multi-Cloud | Yes | AWS Only | Yes | AWS-focused |
| State Mgmt | Built-in | AWS-managed | Built-in | AWS-managed |
| Module System | Mature | Nested stacks | Libraries | Constructs |
| Community | Largest | AWS-focused | Growing | Growing |
| Language | HCL | JSON/YAML | Any | TypeScript/Python |

## Consequences
- Positive: Industry standard, excellent module ecosystem, state management
- Negative: HCL learning curve (mitigated by extensive documentation)
- Negative: State file management requires S3+DynamoDB backend

## Author
Gopi Krishna Vajrala
