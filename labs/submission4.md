# Lab 4 Submission - SBOM Generation & Software Composition Analysis

**Student:** Palkina Sofia  
**Date:** 2026-02-28

---

## Task 1 — SBOM Generation with Syft and Trivy (4 pts)

### Package Type Distribution Comparison

Both tools detected approximately the same total number of packages (~1,139), showing high consistency

**Syft detected: 1,139 total packages**
- 1,128 npm packages (Node.js dependencies)
- 10 deb packages (Debian OS packages)
- 1 binary

**Syft** categorizes packages by ecosystem type (npm, deb, binary) which provides clearer package type classification

**Trivy detected: 1,139 total packages**
- 1,125 Node.js packages
- 10 OS packages (Debian 12.11)
- 4 individual TypeScript/JavaScript files with embedded dependencies

**Trivy** groups packages by target/location and detected some individual source files (`insecurity.ts`, test files) that contain inline dependencies

---

### Dependency Discovery Analysis

**Strengths of each tool:**

**Syft:**
- Clear ecosystem-based classification (npm, deb, binary)
- Better structured metadata in native JSON format
- Focused on package manager artifacts (package.json, dpkg)
- More suitable for standardized SBOM formats (SPDX, CycloneDX)

**Trivy:**
- Detected individual source files with embedded dependencies (4 files)
- More comprehensive file-system level scanning
- Provides context about package location (container layers, file paths)
- Better for detecting dependencies not declared in manifests

---

### License Discovery Analysis

**License Coverage:**
- **Syft found:** 32 unique license types across 1,155 licensed packages
- **Trivy found:** 
  - OS Packages: 12 unique license types
  - Node.js: 20 unique license types
  - **Total: 27 unique license types** (after deduplication)

**Analysis:**
- **Syft** detected more license variations (32 vs 27) due to preserving original package.json metadata
- **Trivy** provides better license standardization following SPDX 3.0 conventions
- Both tools successfully identified the dominant permissive licenses (MIT, ISC, BSD, Apache)

---

## Task 2 — Software Composition Analysis with Grype and Trivy (3 pts)

### SCA Tool Comparison - Vulnerability Detection Capabilities

**Comparison Analysis:**

| Metric | Grype | Trivy | Difference |
|--------|-------|-------|------------|
| **Total CVEs** | 144 | 143 | ~99% overlap |
| **Critical** | 11 | 10 | Grype +1 |
| **High** | 86 | 81 | Grype +5 |
| **Medium** | 32 | 34 | Trivy +2 |
| **Low** | 3 | 18 | Trivy +15 |

**Key Observations:**
- Both tools detected nearly identical total vulnerability counts (144 vs 143)
- **Grype** is more aggressive in severity classification - found more Critical/High vulnerabilities
- **Trivy** classified more issues as Low severity, showing more conservative risk assessment

Both tools provide **comparable detection capabilities** with minimal differences. Choose based on workflow integration needs rather than detection accuracy.

---

### Top 5 Most Critical Findings

#### 1. CVE: GHSA-whpj-8f3w-67p5 (vm2 Sandbox Escape)
- **Package:** `vm2@3.9.17`
- **Severity:** Critical
- **Impact:** Allows attackers to escape VM sandbox and execute arbitrary code on the host system
- **Exploitability:** High - publicly known exploit available
- **Remediation:** 
  - Upgrade to `vm2@3.9.18` (patch available)
  - Priority: **IMMEDIATE** - actively exploited in the wild
  - Alternative: Replace `vm2` with safer alternatives like `isolated-vm`

#### 2. CVE: GHSA-g644-9gfx-q4q4 (vm2 Sandbox Escape)
- **Package:** `vm2@3.9.17`
- **Severity:** Critical
- **Impact:** Another sandbox escape variant in the same package
- **Exploitability:** High
- **Remediation:**
  - **No direct patch version specified** - requires investigation
  - Priority: **IMMEDIATE**
  - Recommendation: Migrate away from `vm2` entirely (package is deprecated as of 2023)

#### 3. CVE: GHSA-cchq-frgv-rjh5 (vm2 Sandbox Escape)
- **Package:** `vm2@3.9.17`
- **Severity:** Critical
- **Impact:** Third sandbox escape vulnerability in `vm2`
- **Exploitability:** High
- **Remediation:**
  - Upgrade to `vm2@3.10.0` or higher
  - Priority: **IMMEDIATE**

#### 4. CVE: GHSA-c7hr-j4mj-j2w6 (jsonwebtoken Verification Bypass)
- **Package:** `jsonwebtoken@0.1.0` and `jsonwebtoken@0.4.0`
- **Severity:** Critical
- **Impact:** Allows attackers to forge JWT tokens, bypassing authentication completely
- **Exploitability:** Critical - trivial to exploit, breaks entire auth system
- **Remediation:**
  - Upgrade to `jsonwebtoken@4.2.2` or later (current stable: `9.x`)
  - Priority: **CRITICAL** - affects authentication security
  - Note: Current version is severely outdated (2014 vs 2024)

#### 5. Summary: **Multiple Critical Issues in Core Security Components**
- **Root Cause:** Severely outdated dependencies (8-10 years old)
- **Attack Surface:** 
  - Sandbox escape → RCE (Remote Code Execution)
  - JWT bypass → Full authentication compromise
- **Business Impact:** Complete application compromise possible

---

### License Compliance Assessment

**Compliance Summary:**
- **Syft detected:** 32 unique license types
- **Trivy detected:** 28 unique license types
- **Overlap:** Both tools identified the same high-risk licenses

**Risky Licenses Identified:**

#### 🔴 High Risk (Copyleft - Requires Source Disclosure)
- **GPL-2.0** (6 packages) - Strong copyleft, requires full source release
- **GPL-3.0** (4 packages) - Stronger copyleft + patent provisions
- **LGPL** (4 packages) - Library GPL, less restrictive but still copyleft

**Impact:** If Juice Shop were commercial software, these would require:
- Publishing entire application source code
- Allowing derivative works
- Potential patent licensing issues

#### 🟡 Medium Risk (Non-Standard Licenses)
- **WTFPL** ("Do What The F*** You Want") - 3 packages
  - Not OSI-approved
  - Legally ambiguous in some jurisdictions
  - Corporate legal departments typically reject
- **ad-hoc** - 1 package (custom license)
- **public-domain** - 1 package (no legal protection)

#### 🟢 Low Risk (Permissive)
- **MIT** (890 packages) - 77% of all packages 
- **ISC** (143 packages) - 12% 
- **BSD-2/3-Clause** (28 packages) 
- **Apache-2.0** (15 packages) - includes patent grant 

**Compliance Recommendations:**

- Remove all GPL/LGPL dependencies or isolate them in separate services
- Replace WTFPL packages with MIT/Apache alternatives
- Document GPL components in README
- Implement license scanning in CI/CD (Trivy is excellent for this)
- Block PRs introducing GPL/AGPL/unknown licenses
- Maintain license whitelist policy

---

### Secrets Scanning Results

**Trivy Secrets Scan Findings:**

Trivy detected **4 hardcoded secrets** in source code files:

| File | Secret Type | Severity | Description |
|------|-------------|----------|-------------|
| `/juice-shop/build/lib/insecurity.js` | RSA Private Key |  **HIGH** | Asymmetric private key hardcoded in compiled JavaScript |
| `/juice-shop/lib/insecurity.ts` | RSA Private Key |  **HIGH** | RSA private key hardcoded in TypeScript source |
| `/juice-shop/frontend/src/app/app.guard.spec.ts` | JWT Token |  **MEDIUM** | JWT token in test file (line 38) |
| `/juice-shop/frontend/src/app/last-login-ip/last-login-ip.component.spec.ts` | JWT Token |  **MEDIUM** | JWT token in test file (line 61) |

**Security Analysis:**

1. **CRITICAL: RSA Private Keys Exposed**
   - **Location:** `insecurity.ts` (source) and `insecurity.js` (compiled build artifact)
   - **Risk:** Private key for JWT signing is hardcoded in application code
   - **Impact:** 
     - Anyone with access to the code can forge valid JWT tokens
     - Breaks entire authentication system
     - No way to rotate keys without code deployment
   - **Remediation:**
     ```bash
     # Move keys to environment variables
     export JWT_PRIVATE_KEY_PATH=/secure/path/jwt.key
     
     # Use secrets management (HashiCorp Vault, AWS Secrets Manager, etc.)
     # Never commit private keys to git repository
     ```

2. **MEDIUM: JWT Tokens in Test Files**
   - **Location:** Test spec files (`.spec.ts`)
   - **Risk:** Real or example JWT tokens in test code
   - **Impact:** 
     - If real tokens: potential unauthorized access
     - If example tokens: reveals JWT structure/claims
   - **Best Practice:**
     ```typescript
     // Generate test tokens dynamically instead
     const testToken = generateMockJWT({ userId: 'test123' });
     localStorage.setItem('token', testToken);
     ```

**Prevention Strategy:**

- Use git-secrets or pre-commit hooks to block commits with secrets
-  Store sensitive data in environment variables or secrets managers
-  Rotate all credentials if accidentally committed (assume compromised)
-  Add .gitignore rules for key files, .env, *.pem, *.key


## Task 3 — Toolchain Comparison: Syft+Grype vs Trivy All-in-One (3 pts)

### Accuracy Analysis - Package Detection and Vulnerability Overlap

#### Package Detection Comparison

| Metric | Count | Percentage |
|--------|-------|------------|
| **Packages detected by both tools** | 988 | 97.7% overlap |
| **Packages only detected by Syft** | 13 | 1.3% unique |
| **Packages only detected by Trivy** | 10 | 1.0% unique |
| **Total unique packages (union)** | 1,011 | 100% |


#### Vulnerability Detection Overlap


| Metric | Grype | Trivy | Overlap |
|--------|-------|-------|---------|
| **Total unique CVEs** | 93 | 91 | 26 (27.96%) |
| **CVEs only detected** | 67 (72%) | 65 (71%) | — |
| **Agreement rate** | **27.96%** | **27.96%** | **Low** |


This is a **significant discrepancy** - **Single tool is insufficient for comprehensive vulnerability detection**

**Sample of Unique CVEs:**

**Grype-only CVEs (first 5):**
- CVE-2025-55130
- CVE-2025-55131
- CVE-2025-55132
- CVE-2025-59465
- CVE-2025-59466

**Trivy-only CVEs (first 5):**
- CVE-2015-9235
- CVE-2016-1000223
- CVE-2016-1000237
- CVE-2016-4055
- CVE-2017-16016

**Root Cause Analysis:**

1. **Different Vulnerability Databases:**
   - **Grype** uses: NVD + GitHub Security Advisories (GHSA) + OS-specific feeds
   - **Trivy** uses: NVD + Red Hat + Debian + Alpine + custom sources
   - **Result:** Each tool has access to different vulnerability intelligence

2. **CVE Matching Algorithms:**
   - **Grype**: Matches CVEs to packages using CPE (Common Platform Enumeration)
   - **Trivy**: Uses package-specific vulnerability feeds (npm advisory, Go vulndb, etc.)
   - **Result:** Same package may match different CVEs

3. **Version Range Interpretation:**
   - Different tools interpret "affected versions" differently
   - Example: `<4.0.0` vs `>=3.0.0, <4.0.0` produce different matches

---

### Tool Strengths and Weaknesses

#### Syft + Grype (Specialized Toolchain)

**Strengths:**
- **Best-in-class SBOM generation** - native support for SPDX, CycloneDX formats
- **Modular architecture** - separate SBOM generation from vulnerability scanning
- **Cacheable SBOMs** - generate once, scan multiple times with different policies
- **Clear separation of concerns** - easier to debug and customize
- **Better for compliance** - SBOM can be stored/shared independently
- **Integration flexibility** - can use Grype with SBOMs from other tools

**Weaknesses:**
- **Two separate tools** - more complex CI/CD integration
- **No secrets scanning** - requires additional tools (truffleHog, git-secrets)
- **No configuration scanning** - can't detect Dockerfile/K8s misconfigurations
- **Steeper learning curve** - need to understand two tool ecosystems
- **More disk space** - SBOM files can be large (10-100MB for big apps)

**Best For:**
- Regulatory compliance requiring SBOM artifacts (NTIA, EO 14028)
- Enterprise environments with dedicated security teams
- CI/CD pipelines with artifact storage (Artifactory, Nexus)
- Organizations needing SBOM analytics/tracking over time

---

#### Trivy (All-in-One Solution)

**Strengths:**
- **One tool, multiple scanners** - vuln + secrets + config + SBOM in single command
- **Simpler CI/CD integration** - one Docker image, one command
- **Faster for ad-hoc scans** - no intermediate SBOM file needed
- **Broader security coverage** - detects misconfigurations, secrets, licenses
- **Better for developers** - simpler mental model, less tooling overhead
- **Active development** - rapid feature additions, strong community

**Weaknesses:**
- **Less modular** - can't easily swap out components
- **SBOM format limitations** - primarily JSON, limited SPDX/CycloneDX support
- **Tighter coupling** - harder to use SBOM separately from scanning
- **Database updates** - requires frequent updates for accuracy
- **Less suitable for SBOM-first workflows** - SBOM is secondary to scanning

**Best For:**
- Startups and small teams needing comprehensive scanning quickly
- Developer workstations - simple local security checks
- Simple CI/CD pipelines - single step for multiple checks
- Container-focused workflows - excellent Docker/K8s integration
- Fast iteration environments - quick feedback loops

---
##  CI/CD Pipeline Recommendations

```YAML
# Option 1: Syft + Grype (SBOM-first)
- name: Generate SBOM
  uses: anchore/sbom-action@v0
  with:
    image: myapp:latest
    format: cyclonedx-json
    
- name: Scan SBOM
  uses: anchore/scan-action@v3
  with:
    sbom: sbom.cyclonedx.json
    fail-build: true
    severity-cutoff: high

# Option 2: Trivy (all-in-one)
- name: Run Trivy
  uses: aquasecurity/trivy-action@master
  with:
    scan-type: image
    image-ref: myapp:latest
    scanners: vuln,secret,config
    exit-code: 1
    severity: CRITICAL,HIGH
```
