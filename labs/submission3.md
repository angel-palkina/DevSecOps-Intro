# Lab 3 Submission — Secure Git

**Student:** Palkina Sofia 
**Date:** 2026-02-22

---

## Task 1 — SSH Commit Signature Verification 

### 1.1 Benefits of Commit Signing

Commit signing ensures:
- **Authenticity**: Verifies that commits were made by the claimed author
- **Integrity**: Ensures commits haven't been tampered with
- **Non-repudiation**: Provides cryptographic proof of authorship
- **Trust**: Critical in DevSecOps for supply chain security

### 1.2 SSH Signing Configuration

Commands executed: ![alt text](./images/02-lab3-comans-executed.png)


SSH Key added to GitHub: ![alt text](./images/03-lab3-ssh-keys.png)

### 1.3 Analysis: Why is commit signing critical in DevSecOps?
In DevSecOps workflows, commit signing is critical because:

- It prevents unauthorized code injection into repositories
- Provides accountability in collaborative environments
- Enables audit trails for compliance and security reviews
- Protects against supply chain attacks (compromised developer accounts)
- Ensures code provenance verification in CI/CD pipelines

### 1.4 Evidence of Signed Commits
![alt text](./images/04-lab3-Evidence-Signed-Commits.png)


---

## Task 2 — Pre-commit Secret Scanning (5 pts)

### 2.1 Pre-commit Hook Setup

**Hook Location:** `.git/hooks/pre-commit`

**Configuration Details:**
- **Tools Used:** TruffleHog + Gitleaks (via Docker)
- **Scanning Scope:** All staged files except `lectures/*` directory
- **Windows Compatibility:** Fixed path handling for Docker on Windows (`C:/Users/...` format)

**Key Implementation Features:**
```bash
# Windows Docker path fix
REPO_PATH="C:/Users/sofia/Desktop/IU/DevSecOps/Lab1/DevSecOps-Intro"

# TruffleHog scan
docker run --rm -v "${REPO_PATH}:/repo" trufflesecurity/trufflehog:latest filesystem ...

# Gitleaks scan
docker run --rm -v "${REPO_PATH}:/repo" zricethezav/gitleaks:latest detect --source="/repo/$file" ...
```

### 2.2 Testing Results

Test 1: File with Secrets (BLOCKED ❌)
File: `test-with-secrets.txt`
```
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
GITHUB_TOKEN=ghp_1234567890abcdefghijklmnopqrstuvwxyz
```
![alt text](./images/06-lab3-deny.png)

Test 2: Clean File (PASSED ✅)
File: `test-clean.txt`

```
DATABASE_URL=postgresql://user:password@localhost:5432/mydb
API_ENDPOINT=https://api.example.com
DEBUG_MODE=false
``` 
![alt text](./images/05-lab3-accept.png)

### 2.3 Analysis: How Secret Scanning Prevents Security Incidents
Automated pre-commit secret scanning prevents security incidents by:

- Early Detection: Catches secrets before they enter version control
- Developer Awareness: Educates developers immediately about security issues
- Zero Trust: Assumes mistakes will happen and provides automated safeguards
- Compliance: Ensures security policies are enforced at the source
- Cost Reduction: Prevents expensive secret rotation and incident response
- Supply Chain Security: Protects against credential leaks in public repositories

Real-world Impact:

- Prevents accidental exposure of API keys, tokens, and passwords
- Stops credentials from appearing in git history (permanent record)
- Reduces risk of unauthorized access to production systems
- Enables "shift-left" security practices in DevSecOps