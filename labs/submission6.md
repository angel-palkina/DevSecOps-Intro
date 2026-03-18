# Lab 6 — Infrastructure-as-Code Security: Scanning & Policy Enforcement

## Student
- GitHub: Palkina Sofa
- Date: `2026-03-16`

---

## Terraform & Pulumi Security Scanning

### 1.1 Tools and scope
I scanned intentionally vulnerable IaC from:
- `labs/lab6/vulnerable-iac/terraform/` with **tfsec**, **Checkov**, **Terrascan**
- `labs/lab6/vulnerable-iac/pulumi/` with **KICS (Checkmarx)**

### 1.2 Terraform scan results (quantitative)

| Tool | Findings |
|---|---:|
| tfsec | **53** |
| Checkov | **78** |
| Terrascan | **22** |

#### Observations
- **Checkov** reported the highest number of failed checks (broad policy coverage).
- **tfsec** found many Terraform-focused issues with clear rule IDs and severities.
- **Terrascan** returned fewer findings, but categorized them clearly by security domain (e.g., Data Protection, IAM, Infrastructure Security).

### 1.3 Terraform findings examples

#### tfsec examples
- `AVD-AWS-0023` (HIGH): Table encryption is not enabled (`database.tf`)
- `AVD-AWS-0104` (CRITICAL): Security group egress to public internet (`security_groups.tf`)
- `AVD-AWS-0124` (LOW): Security group rule missing description (`security_groups.tf`)
- `AVD-AWS-0024` (MEDIUM): Point-in-time recovery is not enabled (`database.tf`)

#### Checkov examples
- `CKV_AWS_16`: RDS encryption at rest is not enabled
- `CKV_AWS_17`: RDS is publicly accessible
- `CKV_AWS_157`: RDS Multi-AZ is not enabled
- `CKV_AWS_293`: RDS deletion protection is not enabled
- `CKV_AWS_161`: IAM authentication for RDS is not enabled

#### Terrascan examples
- `rdsHasStorageEncrypted` (HIGH, Data Protection)
- `rdsPubliclyAccessible` (HIGH, Infrastructure Security)
- `portWideOpenToPublic` (HIGH, Infrastructure Security)
- `allUsersReadAccess` (HIGH, Identity and Access Management)
- `rdsLogExportDisabled` (MEDIUM, Logging and Monitoring)

### 1.4 Pulumi scan results (KICS)

| Tool | Findings | High | Medium | Low |
|---|---:|---:|---:|---:|
| KICS (Pulumi) | **6** | **2** | **1** | **0** |

KICS Pulumi examples:
- `RDS DB Instance Publicly Accessible` (CRITICAL)
- `DynamoDB Table Not Encrypted` (HIGH)
- `Passwords And Secrets - Generic Password` (HIGH)
- `EC2 Instance Monitoring Disabled` (MEDIUM)
- `DynamoDB Table Point In Time Recovery Disabled` (INFO)

### 1.5 Terraform vs Pulumi security issues
- Both stacks expose **core cloud security risks**: public DB access, weak encryption settings, and secrets handling issues.
- Terraform scanners provide deeper IaC-framework-specific coverage and richer location metadata.
- KICS detected important Pulumi risks, including critical exposure and crypto hygiene problems.

### 1.6 KICS Pulumi support evaluation
Strengths:
- Good Pulumi detection (platform-aware findings)
- Multi-format outputs (JSON/HTML/CLI)
- Useful cross-platform security queries (including secrets checks)

Limitations observed:
- In this run, some query fields like `file_name` / `line` were empty in JSON output, reducing traceability in report analysis.


## Ansible Security Scanning with KICS

### 2.1 Ansible scan results

| Tool | Findings | High | Medium | Low |
|---|---:|---:|---:|---:|
| KICS (Ansible) | **10** | **3** | **0** | **1** |

### 2.2 Key Ansible issues identified
Examples from KICS:
- `Passwords And Secrets - Generic Password` (HIGH)
- `Passwords And Secrets - Generic Secret` (HIGH)
- `Passwords And Secrets - Password in URL` (HIGH)
- `Unpinned Package Version` (LOW)

### 2.3 Best-practice violations (at least 3)
1. **Hardcoded secrets/passwords in playbooks or inventory**  
   - Risk: credential leakage, account takeover, lateral movement.
2. **Secrets included in URLs**  
   - Risk: secret exposure in logs, process list, proxies, browser history.
3. **Unpinned package versions**  
   - Risk: non-reproducible builds, accidental vulnerable/new package pull.

### 2.4 Remediation steps (Ansible)
- Move all sensitive data to **Ansible Vault** (or external secret manager).
- Add `no_log: true` for tasks handling credentials/tokens.
- Replace inline credentials and URL-embedded passwords with variables from vault.
- Pin package versions (and define controlled update process).
- Enforce secure file permissions for keys/secrets (`0600`) and reduce privilege scope.


## Comparative Tool Analysis & Security Insights

## 3.1 Comprehensive tool comparison matrix

| Criterion | tfsec | Checkov | Terrascan | KICS |
|---|---|---|---|---|
| **Total Findings** | 53 (Terraform) | 78 (Terraform) | 22 (Terraform) | 6 (Pulumi) + 10 (Ansible) |
| **Scan Speed** | Fast | Medium | Medium | Medium |
| **False Positives** | Low–Medium | Medium | Low–Medium | Medium |
| **Report Quality** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| **Ease of Use** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| **Documentation** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| **Platform Support** | Terraform-focused | Multi-framework | Multi-framework | Multi-framework (incl. Pulumi/Ansible) |
| **Output Formats** | JSON, text, SARIF | JSON, CLI, SARIF, etc. | JSON, human | JSON, HTML, SARIF, CLI |
| **CI/CD Integration** | Easy | Easy/Medium | Medium | Medium |
| **Unique Strengths** | Terraform-first precision | Broad policy catalog | Compliance/domain mapping | Strong Pulumi + Ansible support |

## 3.2 Vulnerability category analysis

| Security Category | tfsec | Checkov | Terrascan | KICS (Pulumi) | KICS (Ansible) | Best Tool (this lab) |
|---|---|---|---|---|---|---|
| Encryption Issues | Strong | Strong | Strong | Medium | N/A | Checkov/tfsec |
| Network Security | Strong | Strong | Strong | Medium | Medium | tfsec/Terrascan |
| Secrets Management | Medium | Medium | Low | High | High | KICS |
| IAM/Permissions | Medium | Strong | Strong | Medium | Low | Checkov/Terrascan |
| Access Control | Strong | Strong | Strong | Medium | Medium | tfsec/Checkov |
| Compliance/Best Practices | Medium | Strong | Strong | Medium | Medium | Checkov/Terrascan |

## 3.3 Top 5 critical findings + remediation code examples

### 1) Publicly accessible RDS (Terraform/Pulumi)
**Risk:** direct exposure of database to internet.  
**Fix principle:** private subnets + restrictive SG + `publicly_accessible = false`.

```hcl
resource "aws_db_instance" "secure_db" {
  publicly_accessible = false
  storage_encrypted   = true
}
```

### 2) Missing encryption at rest (RDS/DynamoDB)
**Risk:** data compromise if storage snapshot/volume is leaked.  
**Fix principle:** enforce encryption + KMS where applicable.

```hcl
resource "aws_db_instance" "secure_db" {
  storage_encrypted = true
  kms_key_id        = aws_kms_key.db.arn
}
```

### 3) Security group too open (0.0.0.0/0)
**Risk:** unrestricted inbound/outbound traffic, attack surface expansion.  
**Fix principle:** narrow CIDRs, explicit ports, least-privilege network policy.

```hcl
cidr_blocks = ["10.0.0.0/16"]
```

### 4) Hardcoded secrets / password in URL (Pulumi/Ansible)
**Risk:** secrets leak via VCS, logs, artifacts.  
**Fix principle:** vault/secret manager, environment injection, no plaintext secrets.

```yaml
# Ansible
- name: Use secret safely
  ansible.builtin.debug:
    msg: "Secret loaded from vault"
  no_log: true
```

### 5) Overly broad IAM permissions
**Risk:** privilege escalation and blast radius increase.  
**Fix principle:** replace wildcard actions/resources with scoped permissions.

```json
{
  "Effect": "Allow",
  "Action": ["s3:GetObject"],
  "Resource": ["arn:aws:s3:::example-bucket/*"]
}
```

## 3.4 Tool selection guide
- **Use tfsec** for fast Terraform-focused checks in pre-commit and PR gates.
- **Use Checkov** for broad policy coverage across multiple IaC artifacts and governance checks.
- **Use Terrascan** when compliance mapping and policy categories matter.
- **Use KICS** when scanning **Pulumi + Ansible** in one unified toolchain.

## 3.5 CI/CD integration strategy (recommended)
1. **Pre-commit/local:** tfsec + lightweight Checkov subset  
2. **PR pipeline:** full Checkov + tfsec + KICS  
3. **Nightly/compliance:** Terrascan + full KICS + SARIF upload to security dashboards  
4. **Policy gate:** block merge on CRITICAL/HIGH unless approved exception exists

## 3.6 Lessons learned
- No single scanner gives complete coverage; overlap is useful.
- Different tools excel in different domains (Terraform precision vs broad compliance vs config/secrets patterns).
- Structured JSON outputs are critical for automation and trend tracking.
