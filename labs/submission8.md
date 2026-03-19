# Lab 8 — Software Supply Chain Security: Signing, Verification, and Attestations

## Student
- Name: Palkina Sofia
- Date: `2026-03-19`

## Target image
- `bkimminich/juice-shop:v19.0.0`
- Local signed reference (original digest):
  - `localhost:5000/juice-shop@sha256:547bd3fef4a6d7e25e131da68f454e6dc4a59d281f8793df6853e6796c9bbf58`

## Task 1 — Local Registry, Signing & Verification

### Results:
- Verification of tampered digest **failed** (as expected):  
  `labs/lab8/signing/verify-after-tamper.txt`
- Verification of original signed digest still **succeeded**:  
  `labs/lab8/signing/verify-original-again.txt`

### Why signing protects against tag tampering
A tag is mutable and can point to different manifests over time.  
A signature is bound to a specific **subject digest** (`sha256:...`), which is immutable.  
Therefore, if a tag is retargeted to another image, verification against the original signature fails for the new digest.


## Task 2 — Attestations (SBOM + Provenance)

### Signature vs attestation
- **Signature** proves integrity/authenticity of the artifact digest (who signed what).
- **Attestation** provides structured metadata linked to the same digest (e.g., SBOM or provenance details).

### What SBOM attestation contains
SBOM attestation contains software component inventory (packages/dependencies), versions, and metadata format/schema (CycloneDX), enabling dependency visibility and policy checks.

### What provenance attestation provides
Provenance describes build context (builder identity, build type, invocation parameters, timestamps).  
It helps establish artifact origin and supports trust decisions in the supply chain.


## Task 3 — Artifact (Blob/Tarball) Signing

### Use cases for blob signing
- Release binaries
- Configuration bundles
- Scripts/policies
- Any non-container distributable artifact

### Blob signing vs image signing
- Blob signing signs a local file directly.
- Image signing signs an OCI artifact digest stored in a registry.
- Both provide integrity/authenticity, but with different artifact types and distribution models.
