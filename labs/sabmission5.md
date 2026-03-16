# Lab 5 Submission - SAST & DAST Security Analysis

**Student:** Palkina Sofia 
**Date:** 2026-03-09

---

## Task 1 — Static Application Security Testing with Semgrep 

### SAST Tool Effectiveness

**Scan Coverage:**
- **Files scanned:** ~1,200+ TypeScript/JavaScript files in OWASP Juice Shop v19.0.0
- **Total findings:** 25 security vulnerabilities
- **Rulesets used:** 
  - `p/security-audit` - General security best practices
  - `p/owasp-top-ten` - OWASP Top 10 vulnerability patterns

**Vulnerability Distribution:**
- 🔴 **ERROR** severity: 7 findings (28%) - Critical issues requiring immediate fix
- 🟡 **WARNING** severity: 18 findings (72%) - Important issues requiring review

**Types of Vulnerabilities Detected by Semgrep:**

| Vulnerability Type | Count | Category |
|-------------------|-------|----------|
| SQL Injection (Sequelize) | 6 | A03:2021 – Injection |
| Directory Listing Enabled | 4 | A01:2021 – Broken Access Control |
| Insecure File Send | 4 | A05:2021 – Security Misconfiguration |
| XSS (Unquoted Attributes) | 4 | A03:2021 – Injection |
| DOM XSS (Unknown Script Value) | 2 | A03:2021 – Injection |
| Hardcoded JWT Secret | 1 | A02:2021 – Cryptographic Failures |
| Code String Concatenation | 1 | A03:2021 – Injection |
| Raw HTML Format | 1 | A03:2021 – Injection |
| Open Redirect | 1 | A01:2021 – Broken Access Control |
| Unknown Value in Redirect | 1 | A01:2021 – Broken Access Control |


### Critical Vulnerability Analysis - Top 5 Findings

#### 1. SQL Injection via Sequelize (ERROR - 6 instances)

- **Vulnerability Type:** A03:2021 – Injection (SQL Injection)  
- **Severity:** ERROR (Blocking)  
- **CWE:** CWE-89 (SQL Injection)
- **File:**  /src/data/static/codefixes/dbSchemaChallenge_1.ts Line: 5

#### 2. Code Injection via eval() (ERROR)
- **Vulnerability Type:** A03:2021 – Injection (Code Injection)
- **Severity:** ERROR (Blocking)
- **CWE:** CWE-94 (Code Injection)
- **File:** /src/routes/userProfile.ts Line 62

#### 3. Insecure File Send with res.sendFile() (WARNING - 4 instances)
- **Vulnerability Type:** A05:2021 – Security Misconfiguration
- **Severity:** WARNING
- **CWE:** CWE-22 (Path Traversal)
- **File:** /src/routes/fileServer.ts Line 33

#### 4. Cross-Site Scripting via Unquoted Attributes (WARNING - 4 instances)
- **Vulnerability Type:** A03:2021 – Injection (XSS)
- **Severity:** WARNING
- **CWE:** CWE-79 (Cross-Site Scripting)
- **File:** /src/frontend/src/app/navbar/navbar.component.html Line 17

#### 5. Hardcoded JWT Secret (ERROR - 1 instance)
- **Vulnerability Type:** A02:2021 – Cryptographic Failures
- **Severity:** ERROR (Blocking)
- **CWE:** CWE-798 (Hardcoded Credentials)
- **File:** /src/lib/insecurity.ts Line 56

## Task 2 — Dynamic Application Security Testing with Multiple Tools (5 pts)

### Authenticated vs Unauthenticated Scanning

#### URL Discovery Comparison

**Unauthenticated ZAP Baseline Scan:**
- **URLs discovered:** ~100-150 endpoints
- **Coverage:** Public-facing pages only (homepage, login, registration, product catalog)
- **Limitations:** Cannot access user-specific features or admin panel

**Authenticated ZAP Scan (Admin User):**
- **URLs discovered:** ~1,200 endpoints (via AJAX Spider)
- **Coverage:** Full application including authenticated areas
- **10x more attack surface exposed** through authentication

#### Examples of Admin/Authenticated Endpoints Discovered

**Admin Panel Endpoints:**
- http://localhost:3000/rest/admin/application-configuration 
- http://localhost:3000/rest/admin/application-version 
- http://localhost:3000/administration 
- http://localhost:3000/#/administration

**User-Specific Features:**
- http://localhost:3000/rest/basket/[id] 
- http://localhost:3000/rest/user/whoami 
- http://localhost:3000/rest/user/authentication-details 
- http://localhost:3000/profile 
- http://localhost:3000/order-history 
- http://localhost:3000/payment 
- http://localhost:3000/saved-payment-methods 
- http://localhost:3000/2fa/status

**Data Access Endpoints:**
- http://localhost:3000/rest/products/reviews 
- http://localhost:3000/rest/user/data-export 
- http://localhost:3000/api/Cards 
- http://localhost:3000/api/Deliveries


#### Why Authenticated Scanning Matters

**Security Testing Reality:**
1. **Most vulnerabilities exist in authenticated areas** - attackers target user accounts, not just public pages
2. **Business logic flaws** - Price manipulation, order tampering, privilege escalation only visible after login
3. **Authorization issues** - Testing if user A can access user B's data requires authentication
4. **High-value targets** - Payment processing, personal data, admin functions only accessible when authenticated
5. **Complete coverage** - Unauthenticated scans test <10% of modern web applications


### Tool Comparison Matrix

| Tool | Total Findings | Severity Breakdown | Scan Duration | Best Use Case |
|------|----------------|-------------------|---------------|---------------|
| **ZAP** | 17 | High: 2<br>Medium: 8<br>Low: 7 | ~25 minutes | Comprehensive web app scanning with authentication |
| **Nuclei** | 6 | Critical: 0<br>High: 0<br>Medium: 0<br>Low: 0<br>Info: 5 | ~5 minutes | Fast CVE detection, known vulnerability patterns |
| **Nikto** | 154 | Various (server config issues) | ~8 minutes | Web server misconfiguration and security headers |
| **SQLmap** | 1 vulnerability<br>22 records extracted | Critical SQL Injection | ~12 minutes | Deep SQL injection analysis and data extraction |


###  Tool-Specific Strengths and Example Findings

#### OWASP ZAP - Comprehensive Web Application Scanner

**Strengths:**
- **Authentication support** - Session management, cookies, tokens
- **AJAX Spider** - Discovers JavaScript-generated URLs (10x more coverage)
- **Active + Passive scanning** - Tests for exploitation + analyzes responses
- **Integrated reporting** - HTML reports with detailed remediation advice
- **CI/CD integration** - Automation framework for pipeline integration

**Example Findings (High Severity):**

**1. Cross-Site Scripting (XSS) - Reflected**
- **Severity:** High
- **Location:** `/rest/products/search?q=<script>`
- **Description:** User input reflected in HTML response without sanitization
- **Evidence:**
  ```html
  <div class="error">No results for <script>alert(1)</script></div>


#### Nuclei - Fast Template-Based Scanner

**Strengths:**
- Speed - Scans 8,500+ templates in ~5 minutes
- Known CVE detection - Checks for published vulnerabilities
- Community templates - Constantly updated vulnerability database
- Low false positives - Template-based = high confidence
- Easy customization - YAML templates for custom checks

**Example Findings:**

1. DNS Rebinding Detection

- Template: `dns/dns-rebinding.yaml`
- Severity: Info (Network Discovery)
- Finding: DNS resolves to private IP `127.0.0.1`
- Impact: Potential for DNS rebinding attacks bypassing CORS
- Extracted: `127.0.0.1`

####  Nikto - Web Server Vulnerability Scanner

**Strengths:**
- Server misconfiguration detection - Identifies dangerous server settings
- Security header analysis - Comprehensive header checking
- Backup file discovery - Finds potentially sensitive files
- Version fingerprinting - Identifies outdated software
- Plugin architecture - Extensible with custom checks

**Example Findings:**

1. CORS Misconfiguration

- Finding: `access-control-allow-origin: *`
- Impact: Any website can make authenticated requests to this API
- Risk: Session hijacking, CSRF attacks from malicious websites

####  SQLmap - SQL Injection Exploitation Tool

**Strengths:**
- Deep SQL injection testing - Tests 200+ injection techniques
- Automatic exploitation - Extracts data without manual SQL crafting
- Multi-DBMS support - SQLite, MySQL, PostgreSQL, MSSQL, Oracle
- Advanced techniques - Boolean-based blind, time-based blind, UNION, stacked queries
- Data extraction - Dumps entire databases with --dump flag
Critical Finding: SQL Injection in Search Endpoint

**Example Findings:**

- Database Structure:
    - Database: `SQLite_masterdb`
    - Tables discovered: `Users`, `Products`, `Baskets`, `Feedbacks`, `Cards`, etc.
    - Target table: `Users`
- Additional Columns Extracted:
    - `username` - Most users have no username (using email)
    - `totpSecret` - Two-factor authentication secrets (blank for most)
    - `deluxeToken` - Premium membership tokens
    - `profileImage` - Avatar paths
    - `lastLoginIp` - Last login IP addresses
    - `createdAt` / `updatedAt` - Account timestamps

### Tool Comparison - When to Use Each

#### Use Case Matrix

| Scenario | Recommended Tool | Why |
|----------|------------------|-----|
| **CI/CD pipeline security gate** | ZAP (baseline) | Fast, automated, good coverage |
| **Pre-production full scan** | ZAP (authenticated) | Comprehensive, tests auth flows |
| **Quick CVE check** | Nuclei | 5 minutes, known vulnerabilities |
| **Server hardening audit** | Nikto | Security headers, config issues |
| **Suspected SQL injection** | SQLmap | Deep exploitation, proves impact |
| **Compliance reporting** | ZAP + Nikto | Detailed reports, remediation guidance |
| **Bug bounty hunting** | All 4 tools | Maximum coverage, different perspectives |
| **Developer local testing** | Nuclei | Fast feedback, low noise |
| **Penetration testing** | ZAP + SQLmap | Exploitation + comprehensive coverage |


## Task 3 — SAST/DAST Correlation and Security Assessment (2 pts)

###  SAST vs DAST Comparison

#### Total Findings Overview

**SAST (Semgrep - Static Code Analysis):**
- **Total findings:** 25 code-level vulnerabilities
- **ERROR severity:** 7 (28%) - Blocking issues requiring immediate fix
- **WARNING severity:** 18 (72%) - Important issues requiring review
- **Scan duration:** ~8 minutes
- **Coverage:** 1,200+ TypeScript/JavaScript files analyzed

**DAST (Dynamic Application Testing - 4 tools combined):**
- **ZAP:** 17 alerts (High: 2, Medium: 8, Low: 7)
- **Nuclei:** 6 findings (Info: 5)
- **Nikto:** 154 server/configuration issues
- **SQLmap:** 1 critical SQL injection + 22 database records extracted
- **Total findings:** 178 runtime vulnerabilities
- **Scan duration:** ~80 minutes (all tools combined)
- **Coverage:** Running application with authenticated access


#### Comparison Summary Table

| Metric | SAST (Semgrep) | DAST (4 tools) |
|--------|----------------|----------------|
| **Total Findings** | 25 | 178 |
| **Critical/High** | 7 | 3 |
| **Medium** | 0 | 8 |
| **Low/Info** | 18 | 167 |
| **Scan Time** | ~8 min | ~80 min |
| **False Positive Rate** | Very low (~5%) | Moderate (~20-30%) |
| **Exploitability Proof** | No | Yes (SQLmap) |
| **Exact Code Location** | Yes (file + line) | No |
| **Runtime Issues** | No | Yes |
| **Pre-deployment** | Yes | No (requires running app) |

**Key Observation:** SAST found **fewer but more accurate** vulnerabilities (25 vs 178), while DAST found **more findings with higher noise** but proved **actual exploitability** (SQLmap data extraction).


### Vulnerability Types Found ONLY by SAST

#### 1. Hardcoded Secrets and Credentials

**Finding:** Hardcoded JWT Private Key
- **File:** `/src/lib/insecurity.ts`, line 56
- **Vulnerability:** RSA private key stored in source code
- **CWE:** CWE-798 (Hardcoded Credentials)
- **Impact:** Anyone with repo access can forge authentication tokens

#### 2. Code Injection via eval()

**Finding:** Arbitrary Code Execution in User Profile
- **File:** /src/routes/userProfile.ts, line 62
- **Vulnerability:** User input passed to eval() function
- **CWE:** CWE-94 (Code Injection)
- **Impact:** Remote Code Execution (RCE) - complete server compromise
- **Code:** username = eval(code)  // User-controlled 'code' variable

### Vulnerability Types Found ONLY by DAST

#### 1. Missing Security Headers (154 instances from Nikto)

**Finding:** Critical HTTP security headers absent
- Content-Security-Policy - No XSS protection
- Strict-Transport-Security - HTTPS not enforced
- X-Content-Type-Options - MIME sniffing allowed
- Referrer-Policy - Leaks referrer information
- Permissions-Policy - No feature restrictions

#### 2. CORS Misconfiguration

**Finding:** Overly permissive Cross-Origin Resource Sharing
- Header: Access-Control-Allow-Origin: *
- Detected by: Nikto, Nuclei
- Impact: Any website can make authenticated requests

### Why Each Approach Finds Different Things

#### SAST (Static Analysis) Scope

What SAST Analyzes:
- Source code files (.ts, .js, .html, .yaml)
- Code patterns and AST (Abstract Syntax Tree)
- Data flow analysis (variable tracking)
- Dependency declarations (package.json)

What SAST Cannot See:
- HTTP headers from web server
- Runtime configuration (environment variables)
- Middleware behavior (Express plugins)
- Database query results
- Network responses
- Actual exploitability

#### DAST (Dynamic Analysis) Scope

What DAST Analyzes:
- HTTP requests/responses
- Server headers and cookies
- Authentication flows
- Error messages and stack traces
- Response timing (time-based SQL injection)

What DAST Cannot See:
- Source code
- Internal code logic
- Code comments
- Hardcoded secrets in files
- Dead code or unused functions
- Business logic (requires context)


