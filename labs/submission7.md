# Lab 7 — Container Security: Image Scanning & Deployment Hardening

## Student
- Name: Palkina Sofia
- Date: `2026-03-18`

## Task 1 — Image Vulnerability & Configuration Analysis

### 1.1 Docker Scout: vulnerability summary

Scanned image: `bkimminich/juice-shop:v19.0.0`

**Overall results (Docker Scout):**
- Critical: **11**
- High: **64**
- Medium: **30**
- Low: **5**
- Unspecified: **7**
- Total: **117 vulnerabilities in 48 packages**

### 1.2 Top 5 Critical/High vulnerabilities

| # | Vulnerability | Package | Severity | Impact |
|---|---|---|---|---|
| 1 | `SNYK-UPSTREAM-NODE-14928492` (Race Condition) | `node@22.18.0` | Critical | Race conditions may lead to unstable behavior, potential privilege misuse, or security bypass in concurrent operations. |
| 2 | `SNYK-UPSTREAM-NODE-14928586` (UNIX Symlink Following) | `node@22.18.0` | High | Can allow access to unintended files via malicious symbolic links (path traversal-like effects). |
| 3 | `SNYK-UPSTREAM-NODE-14929624` (Uncaught Exception) | `node@22.18.0` | High | Unhandled exceptions can be used for denial-of-service by crashing the process. |
| 4 | `SNYK-UPSTREAM-NODE-14975915` (Reliance on Undefined/Implementation-Defined Behavior) | `node@22.18.0` | High | Undefined behavior can produce unpredictable security outcomes across environments. |
| 5 | `SNYK-DEBIAN12-OPENSSL-15123192` (`CVE-2025-69421`) | `openssl/libssl3` | High | TLS/crypto library vulnerabilities can compromise confidentiality/integrity of encrypted communications. |

### 1.3 Dockle configuration findings

**FATAL findings:** none  
**WARN findings:** none

**INFO/SKIP findings observed:**
- `CIS-DI-0005`: Content trust not enabled (`DOCKER_CONTENT_TRUST=1` recommended)
- `CIS-DI-0006`: Missing `HEALTHCHECK` instruction
- `DKL-LI-0003`: Unnecessary files found (`.DS_Store` in node_modules)
- `DKL-LI-0001` (SKIP): could not detect `/etc/shadow`/`/etc/master.passwd`

### 1.4 Security posture assessment

- Image has a **large number of vulnerabilities**, including Critical and High.
- Configuration scan did not show FATAL/WARN, but reveals best-practice gaps (content trust, healthcheck, image hygiene).
- Recommended improvements:
  1. Update base image and vulnerable dependencies (especially Node/OpenSSL paths).
  2. Add `HEALTHCHECK` in Dockerfile.
  3. Enable Docker Content Trust in CI/CD.
  4. Remove unnecessary files from build context/image layers.
  5. Rebuild image regularly and enforce vulnerability gates in pipeline.

### 1.5 Does the image run as root?

No.  
Direct inspection shows:

- `docker image inspect bkimminich/juice-shop:v19.0.0 --format "{{.Config.User}}"` → `65532`

User ID `65532` is a non-root user (root is UID `0`).  
So the image is configured to run as non-root by default, which is a positive security practice.  
Additional runtime hardening is still recommended (`--cap-drop=ALL`, `--security-opt=no-new-privileges`, resource limits, seccomp profile).

## Task 2 — Docker Host Security Benchmarking (CIS)

Benchmark output file: `labs/lab7/hardening/docker-bench-results.txt`

### 2.1 Summary statistics

- PASS: **19**
- WARN: **49**
- INFO: **111**
- NOTE: **7**

### 2.2 Analysis of failures/warnings

A high WARN count indicates multiple host/daemon/runtime hardening gaps. Typical risk categories:
- Docker daemon and socket exposure issues
- Insufficient isolation and runtime hardening defaults
- Weak auditing/logging controls
- Missing least-privilege restrictions in container runtime settings

### 2.3 Remediation approach

1. Restrict Docker socket access and daemon exposure.
2. Enforce least privilege (`--cap-drop`, `no-new-privileges`, non-root users).
3. Apply resource controls (memory/CPU/PIDs).
4. Enable stronger auditing and centralized logs.
5. Integrate CIS checks into periodic security baseline reviews.


## Task 3 — Deployment Security Configuration Analysis

Comparison evidence: `labs/lab7/analysis/deployment-comparison.txt`

### 3.1 Configuration comparison table

| Setting | Default | Hardened | Production |
|---|---|---|---|
| HTTP status | 200 | 200 | 000 (container exited) |
| CapDrop | `<no value>` | `[ALL]` | `[ALL]` |
| CapAdd | `<no value>` | `<no value>` | `[CAP_NET_BIND_SERVICE]` |
| SecurityOpt | `<no value>` | `[no-new-privileges]` | `[no-new-privileges, seccomp=custom-profile]` |
| Memory limit | 0 (unlimited) | 512 MiB | 512 MiB |
| CPU quota | 0 | 0 | 0 |
| PIDs limit | `<no value>` | `<no value>` | 100 |
| Restart policy | `no` | `no` | `on-failure` |

### 3.2 Security measure analysis

#### a) `--cap-drop=ALL` and `--cap-add=NET_BIND_SERVICE`
- Linux capabilities split root privileges into smaller units.
- `--cap-drop=ALL` removes broad kernel-level powers, reducing privilege escalation and post-exploitation options.
- `NET_BIND_SERVICE` is added back only if binding privileged ports is required.
- Trade-off: stronger security, but some app/system operations may fail without explicitly re-added caps.

#### b) `--security-opt=no-new-privileges`
- Prevents processes from gaining additional privileges (e.g., through setuid binaries).
- Mitigates privilege escalation attempts after compromise.
- Downside: software relying on privilege elevation may break.

#### c) `--memory=512m` and `--cpus=1.0`
- Without limits, one container can consume host resources and affect availability of all services.
- Memory limits reduce DoS blast radius and OOM abuse.
- Limits set too low can cause instability, latency, crashes, or restart loops.

#### d) `--pids-limit=100`
- Fork bomb = process-spawning attack exhausting host PID table/resources.
- PID limit constrains process explosion inside container.
- Proper limit should be based on normal app process/thread behavior under peak load.

#### e) `--restart=on-failure:3`
- Restarts container automatically only on failure, up to 3 retries.
- Useful for transient failures and better service resilience.
- Risk: repeated restart attempts can hide root cause temporarily and create noisy failure loops.
- `on-failure` is safer than `always` for avoiding endless restart storms when persistent misconfiguration exists.

### 3.3 Critical thinking

1. **Best for development:** Default or lightly Hardened profile.  
   Reason: easier debugging and fewer compatibility constraints.

2. **Best for production:** Hardened/Production-style profile with least privilege and resource controls.  
   Reason: smaller attack surface and improved resilience.

3. **Real-world problem solved by resource limits:**  
   Prevent noisy-neighbor effects and container-level DoS from exhausting host memory/CPU/PIDs.

4. **If attacker exploits Default vs Production:**  
   Production blocks many escalation paths (dropped capabilities, no-new-privileges, PID limits, restart policy constraints), reducing attacker freedom and impact.

5. **Additional hardening to add:**  
   - Run as non-root user (`USER` in Dockerfile)
   - Read-only root filesystem (`--read-only`)
   - Drop all unused mounts
   - Add AppArmor/SELinux profile
   - Network segmentation and egress restrictions
   - Continuous image patching and CI vulnerability gates
