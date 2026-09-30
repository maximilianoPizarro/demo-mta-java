# Curated sample-app issues for denser MTA reports

**Date:** 2026-09-30  
**Status:** implemented  
**Repo:** demo-mta-java  
**Approach:** A — curated finding matrix (approved)

## Goal

Enrich `sample-app` (Java 8, analysis input) so the five MTA CLI static reports show a **denser, differentiated Issues list** on GitHub Pages, without changing the demo narrative (WebLogic stays; no EAP/Quarkus/Open Liberty migration).

## Non-goals

- Inflating story points by copy-pasting the same finding dozens of times
- Switching analyze mode from `source-only` to `full` as the primary fix
- Changing Pages comparison UI (out of scope for this change)
- Shipping real Oracle ADF/BC4J jars

## Constraints (unchanged)

- Analysis input remains `sample-app/` on Java 8
- WebLogic remains the application server
- Custom BC4J rules stay content/file based (string / config matches)
- `solutions/java11|17|21` are operational JDK conversions, not “clean cloud” apps

## Current baseline (Pages summaries)

| Target | Incidents | Story points | Gap |
|---|---:|---:|---|
| openjdk11 | 2 | 4 | Thin; JAXB/`Thread.stop`/`Date` barely surface in source-only |
| openjdk17 | 2 | 4 | Same |
| openjdk21 | 4 | 6 | Only a couple of UTF-8 / removal extras |
| cloud-readiness | 6 | 16 | OK but few distinct rule IDs |
| bc4j | 15 | 50 | Strongest; can add 1–2 clearer Java-side Entity/View hits |

## Design

### 1. Add small, intentional classes in `sample-app`

Each class documents *why* MTA should flag it. Wire every entry point from `App.main` (or a `DemoFindings.touchAll()` called once) so nothing is dead code.

| New / extended type | Primary targets | Pattern |
|---|---|---|
| `LegacyEncoding` (extend) | openjdk11/17/21 | Keep `BASE64Encoder`; add `com.sun.image.codec.jpeg` usage if it still compiles on 8 / is flagged as in current report lore |
| `JavaxEeApisDemo` (new) | openjdk11+ | Explicit `javax.activation.DataHandler` / MIME + keep JAXB (`XmlBindingDemo`) |
| `DeprecatedApis` (harden) | openjdk17+ | Ensure `Thread.stop` and deprecated `Date` ctor are invoked in a way source rules match; add `SecurityManager` get if useful |
| `LegacyUrlFactory` (new) | openjdk21 | `new URL(String)` (and related) for modern JDK rules |
| `CharsetIoDemo` (new) | openjdk21 | Extra `FileReader`/`FileWriter` without charset |
| `CloudLocalhostClients` (new) | cloud-readiness | `http://127.0.0.1:…`, absolute `FileInputStream`, `user.home` path join |
| `EmbeddedSocketProbe` (new) | cloud-readiness | Clear `Socket`/`ServerSocket` to localhost |
| `Bc4jCustomerEntity` / `Bc4jOrderView` (new) | bc4j | Java sources containing `oracle.jbo.server.EntityImpl` / `ViewObjectImpl` FQCN strings (same compile-without-Oracle pattern as today) |
| Optional resource | bc4j | One extra tiny `*.jpx` or fragment only if it adds a distinct file hit without noise |

### 2. Maven (`sample-app/pom.xml`)

- Add `javax.activation:javax.activation-api` (provided), mirroring JAXB, so activation usage is realistic for WebLogic/`provided` EE APIs
- Stay on compiler 1.8

### 3. Solutions mirroring

| Change in sample-app | `solutions/java11` | `solutions/java17` | `solutions/java21` |
|---|---|---|---|
| sun.misc / JPEG / activation / JAXB | Fix or add explicit deps as already done for Base64/JAXB | Same + 17-specific fixes | Same + URL/charset fixes |
| `Thread.stop` / deprecated Date | Prefer rewrite to safe APIs where the solution JDK forbids them | Required | Required |
| cloud-readiness patterns | **Leave** (demo debt) | Leave | Leave |
| BC4J string/config markers | **Leave** (certification narrative) | Leave | Leave |

New solution files for any new sample classes that need JDK-safe rewrites; cloud/BC4J-oriented new classes can be copied through unchanged.

### 4. Verify and republish

1. `mvn -f sample-app/pom.xml -q package` (Java 8)
2. `mvn -f solutions/java11|17|21 package` on appropriate JDKs (or document if only 8/11 available locally)
3. `make analyze-all && make publish-reports`
4. Confirm Pages summaries: OpenJDK reports clearly denser than baseline; cloud and BC4j gain distinct new rule hits; no EAP/Quarkus noise
5. Push so Actions redeploys GitHub Pages

### 5. Docs

- Short README note under the MTA CLI section: sample intentionally embeds a curated finding matrix; regenerate Pages after analyze
- Do not claim customer/Oracle code

## Success criteria

- openjdk11 and openjdk17 incidents **materially above** the current 2 (target band ~6–12 each, not hundreds)
- openjdk21 shows both mandatory and potential Issues beyond today’s 4
- cloud-readiness adds ≥2 new distinct rule IDs or clear extra files in Issues
- bc4j shows Entity/View hits from **Java** sources, not only `Model.jpx`
- `sample-app` still builds on Java 8; solutions still express the JDK conversion story
- Published `docs/mta-reports/` regenerated and Pages URL still works

## Implementation notes

- Prefer patterns already known to fire under MTA 8.3 `source-only` on this repo; if a candidate produces zero incidents after analyze, drop or replace it (no dead “fake” narrative in README)
- Keep classes small and named for demo clarity (`…Demo`, `Legacy…`, `Bc4j…`)
- Sanitize/publish path behavior unchanged (`scripts/publish-mta-reports.sh`)

## Out of scope follow-ups

- Pages Issues UI enrichment
- `mta-ops` / cluster migrate narrative
- Full-mode CI analyze in GitHub Actions (optional later)
