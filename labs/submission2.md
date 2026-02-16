# Lab 2 — Threat Modeling with Threagile

## Task 1 — Baseline Threat Model

### Risk Ranking Methodology

Each risk was ranked using the required composite score formula: `Composite Score = Severity × 100 + Likelihood × 10 + Impact`


**Weights used:**

- **Severity:**  critical (5), elevated (4), high (3), medium (2), low (1)

- **Likelihood:**  very-likely (4), likely (3), possible (2), unlikely (1)

- **Impact:**  high (3), medium (2), low (1)


### Top 5 Risks

| # | Risk Category | Affected Asset / Link | Severity | Likelihood | Impact | Composite Score |
|---|--------------|-----------------------|----------|------------|--------|-----------------|
| 1 | Unencrypted Communication | User Browser → Juice Shop (Direct) | Elevated (4) | Likely (3) | High (3) | **433** |
| 2 | Cross-Site Scripting (XSS) | Juice Shop Application | Elevated (4) | Likely (3) | Medium (2) | **432** |
| 3 | Missing Authentication | Reverse Proxy → Juice Shop | Elevated (4) | Likely (3) | Medium (2) | **432** |
| 4 | Unencrypted Communication | Reverse Proxy → Juice Shop | Elevated (4) | Likely (3) | Medium (2) | **432** |
| 5 | Cross-Site Request Forgery (CSRF) | User Browser → Juice Shop | Medium (2) | Very-Likely (4) | Low (1) | **241** |

---

### Risk Analysis

Key security observations:

- **Plaintext HTTP communication** is the most critical issue (score 433), exposing credentials, tokens, and session identifiers to interception via Man-in-the-Middle attacks.
- **XSS remains a high-risk category** (score 432), reflecting Juice Shop's intentionally vulnerable nature and lack of client-side/output sanitization guarantees.
- **Missing authentication** (score 432) between reverse proxy and application enables lateral movement if an attacker gains internal network access.
- **CSRF risks** (score 241) are very likely due to browser-based interactions without anti-CSRF tokens or SameSite cookie enforcement.
- Several medium/low risks (missing vault, missing hardening, missing WAF) indicate absent defense-in-depth controls rather than direct vulnerabilities.

### Artifacts

Generated in `labs/lab2/baseline/`:

- `report.pdf` — full threat modeling report 
- Data Flow Diagram ![(PNG)](lab2/baseline/data-flow-diagram.png)
- Data Asset Diagram ![(PNG)](lab2/baseline/data-asset-diagram.png)
- `risks.json`
- `stats.json`
- `technical-assets.json`

---

## Task 2 — Secure HTTPS Variant & Risk Comparison

### Model Changes

A secure variant was created in `labs/lab2/threagile-model.secure.yaml` with the following modifications:

| Component | Original | Secure Variant |
|-----------|----------|----------------|
| User Browser → Direct to App | `protocol: http` | `protocol: https` |
| Reverse Proxy → To App | `protocol: http` | `protocol: https` |
| Persistent Storage | `encryption: none` | `encryption: transparent` |

### Risk Category Delta Table

| Category | Baseline | Secure | Δ |
|---|---:|---:|---:|
| container-baseimage-backdooring | 1 | 1 | 0 |
| cross-site-request-forgery | 2 | 2 | 0 |
| cross-site-scripting | 1 | 1 | 0 |
| missing-authentication | 1 | 1 | 0 |
| missing-authentication-second-factor | 2 | 2 | 0 |
| missing-build-infrastructure | 1 | 1 | 0 |
| missing-hardening | 2 | 2 | 0 |
| missing-identity-store | 1 | 1 | 0 |
| missing-vault | 1 | 1 | 0 |
| missing-waf | 1 | 1 | 0 |
| server-side-request-forgery | 2 | 2 | 0 |
| **unencrypted-asset** | **2** | **1** | **-1** |
| **unencrypted-communication** | **2** | **0** | **-2** |
| unnecessary-data-transfer | 2 | 2 | 0 |
| unnecessary-technical-asset | 2 | 2 | 0 |


### Delta Analysis

#### Specific Changes Made
1. **HTTPS for direct user communication** — encrypts all user traffic including authentication credentials
2. **HTTPS for reverse proxy communication** — secures internal service-to-service communication  
3. **Transparent storage encryption** — protects data at rest from physical storage compromise

#### Observed Improvements
- **Unencrypted communication risks eliminated** (↓ -2): Both communication paths now use HTTPS, removing exposure of sensitive data in transit
- **Unencrypted asset risk reduced** (↓ -1): Persistent storage encryption addresses one of two unencrypted asset findings

#### Why Other Risks Remain Unchanged
- **Application-layer vulnerabilities** (XSS, CSRF, SSRF) are unaffected by transport encryption — these require code-level fixes
- **Architectural gaps** (missing WAF, vault, identity store, MFA) persist because HTTPS alone doesn't provide these security controls
- **Juice Shop's intentionally vulnerable design** still drives many residual risks regardless of transport security

#### Visual Comparison

The baseline data flow diagram shows HTTP connections from both User Browser and Reverse Proxy to the Juice Shop Application, with unencrypted Persistent Storage. In the secure variant, all communication links are upgraded to HTTPS, and the storage element now displays an encryption lock icon. The data asset diagram reflects this change by marking Persistent Storage as encrypted, though all other data assets (User Accounts, Orders, Tokens & Sessions) remain unchanged. This visual confirmation demonstrates that transport and storage encryption improvements are properly reflected in the model, while application-layer data assets continue to face the same inherent risks.

