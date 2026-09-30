# Demo MTA: esfuerzo Java 8 a 11/17/21 y aptitud a contenedores, sin cambiar WebLogic

[![Open in Dev Spaces](https://img.shields.io/badge/Open%20in-Dev%20Spaces-EE0000?style=for-the-badge&logo=redhat&logoColor=white)](https://github.com/maximilianoPizarro/demo-mta-java#dev-spaces)

Demo sintética con Migration Toolkit for Applications: mide el esfuerzo de pasar de Java 8 a OpenJDK 11, 17 y 21 y la aptitud a contenedores. WebLogic se queda como servidor de aplicaciones; no hay migración a EAP, Quarkus ni Open Liberty.

El mismo repositorio Git alimenta:

1. El build/deploy de la app de ejemplo y las tres conversiones operativas (Helm)
2. El análisis de MTA (código en `sample-app`, reglas BC4J en `rules/bc4j`)
3. El workspace de Dev Spaces (IDE + extensión MTA)

## Pattern (hub-only, CPU)

Un solo cluster, sin spokes y sin GPU. El Pattern CR de escenario A está en `examples/pattern-cr/hub-only-cpu.yaml`.

| Pieza | Chart | Qué hace |
|---|---|---|
| MTA | `charts/mta-demo` | Operador, Hub, app Java 8 y Routes de las conversiones 11/17/21 |
| Dev Spaces | `charts/devspaces` | IDE en el browser sobre este repo |
| Serverless | `charts/openshift-serverless` | Knative Serving |
| Inferencia CPU | `charts/cpu-inference` | Qwen2.5-Coder-7B con tool calling, escala desde cero |

### RHDP Field Content

Pedido Field Content CI con:

| Campo | Valor |
|---|---|
| Repositorio | `https://github.com/maximilianoPizarro/demo-mta-java.git` |
| Branch | `main` |
| GitOps path | **`examples/bootstrap`** |
| Workers (AWS) | **2 × m5a.4xlarge** (16 vCPU / 64 Gi) |
| OpenShift AI / AAP | desmarcados |
| Modelo catálogo | `granite-3-2-8b-instruct` (fallback; la demo usa Qwen en-cluster) |
| Users | 1 |

El chart `examples/bootstrap` instala el Validated Patterns Operator y el Pattern CR. El repo en `main` ya incluye ese entrypoint.

En un cluster ya existente (instala también las Subscriptions de MTA, Serverless y Dev Spaces):

```bash
make deploy
```

Instalación GitOps (Validated Patterns Operator ya instalado):

```bash
oc apply -f examples/pattern-cr/hub-only-cpu.yaml
```

## Contenido

| Ruta | Rol |
|------|-----|
| `sample-app/` | App Maven Java 8 con hallazgos de OpenJDK, cloud-readiness y BC4J simulado |
| `solutions/java11/` | Conversión operativa a OpenJDK 11 (Base64 + JAXB + cloud readiness) |
| `solutions/java17/` | Acumulativa a OpenJDK 17 (Date / Thread.stop) |
| `solutions/java21/` | Acumulativa a OpenJDK 21 (`URI` en lugar de `new URL(String)`) |
| `scripts/mta-cli-analyze.sh` | Un análisis MTA CLI por target (o `all`); pensado para Dev Spaces |
| `scripts/install-mta-cli.sh` | Instala `mta-cli`/`kantra` en `.tools/bin` |
| `.konveyor/hub-profiles/` | Perfiles por reporte (`openjdk11`, `openjdk17`, `openjdk21`, `cloud-readiness`, `bc4j`) |
| `rules/bc4j/` | Ruleset custom (certificación ADF/BC4J, no cambio de servidor) |
| `charts/mta-demo/` | Helm: apps + reporte de esfuerzo (Route) + operador MTA Hub (si hay cluster-admin) |
| `examples/bootstrap/` | Entrypoint RHDP: Subscription del patterns-operator + Pattern CR |
| `reports/` | HTML de visualización de story points / incidentes (sandbox sin admin) |
| `devfile.yaml` | Workspace Dev Spaces con Java y extensión MTA |

## Requisitos

- `oc`, `helm` 3.x
- Cluster OpenShift
- **Ciclo completo (app + MTA):** usuario con `cluster-admin` (OLM crea CRDs)
- **Solo app (Developer Sandbox):** sin admin; usar `mta.enabled=false`
- Repo Git público alcanzable por el cluster (o build binario local)

## Instalación

### 1. Login

```bash
export OC_TOKEN='<token>'   # no commits ni README
oc login --token="$OC_TOKEN" --server=https://api.<cluster>:6443
oc whoami
```

### 2. Elegir modo según permisos

```bash
oc auth can-i create subscriptions.operators.coreos.com --all-namespaces
oc auth can-i create customresourcedefinitions.apiextensions.k8s.io
```

Si ambos responden `yes`:

```bash
# Preferí make deploy (activa las Subscriptions). Helm solo del chart MTA:
helm upgrade --install mta-demo ./charts/mta-demo \
  -n mta-demo --create-namespace \
  --set mta.subscription.enabled=true \
  --set git.uri=https://github.com/maximilianoPizarro/demo-mta-java.git \
  --set git.ref=main
```

Si responden `no` (Developer Sandbox):

```bash
oc project <usuario>-dev
helm upgrade --install mta-demo ./charts/mta-demo \
  -n <usuario>-dev \
  --set mta.enabled=false \
  --set solutions.enabled=false \
  --set app.build.enabled=false \
  --set reports.enabled=true \
  --set git.uri=https://github.com/maximilianoPizarro/demo-mta-java.git

oc start-build mta-java-demo -n <usuario>-dev --from-dir=./sample-app --follow
oc start-build mta-effort-report -n <usuario>-dev --from-dir=./reports --follow
```

En el sandbox **no** se puede instalar la consola Hub del operador MTA (hace falta `cluster-admin`). Red Hat no publica un Helm chart aparte de la UI: la consola viene del Operator. En sandbox usás la Route del **reporte de esfuerzo** (`mta-effort-report`) para ver story points e incidentes.

### 3. Repo Git

El chart ya apunta a `https://github.com/maximilianoPizarro/demo-mta-java.git` (`sample-app` para el análisis, `rules/bc4j` para las reglas custom). El Hub clona ese repo público; no hace falta un token de GitHub.

Si el cluster no puede clonar (sandbox sin build desde Git):

```bash
helm upgrade --install mta-demo ./charts/mta-demo \
  -n <namespace> \
  --set mta.enabled=false \
  --set solutions.enabled=false \
  --set app.build.enabled=false \
  --set reports.enabled=true

oc start-build mta-java-demo -n <namespace> --from-dir=./sample-app --follow
oc start-build mta-effort-report -n <namespace> --from-dir=./reports --follow
```

### 4. Verificar

```bash
oc get route,pods,job -n <namespace>
oc logs -n <namespace> job/mta-demo-mta-demo-mta-bootstrap -f   # solo si mta.enabled=true
```

- **App Java 8:** `oc get route mta-java-demo -n <namespace>`
- **Conversiones:** `oc get route mta-java-11 mta-java-17 mta-java-21 -n <namespace>`
- **Reporte de esfuerzo (HTML):** `oc get route mta-effort-report -n <namespace>` — story points OpenJDK / cloud-readiness / BC4J
- **Consola MTA Hub (producto):** solo con `mta.enabled=true` + cluster-admin. Route `*ui*` / `*mta*`. Login: `admin` / `admin`
- Targets: `openjdk11`, `openjdk17`, `openjdk21`, `cloud-readiness`, `bc4j`
- **No** se seleccionan EAP, Quarkus ni Open Liberty

## Dev Spaces

Abrí este repo en el Dev Spaces del cluster:

`https://devspaces.<apps-domain>/#https://github.com/maximilianoPizarro/demo-mta-java`

Dev Spaces instala al arrancar las extensiones de `.vscode/extensions.json` y `.che/extensions.json` (`redhat.java`, Maven y `redhat.mta-vscode-extension`). El `postStart` (`scripts/devspaces-setup.sh`) copia `.konveyor/provider-settings.yaml` y reescribe `baseURL` con el host de la Route `mta-llm` de este cluster. El build de la sample usa JDK 8.

Si el workspace ya estaba abierto, detenerlo y volver a entrar para que tome este devfile. Perfiles de análisis (extensión MTA y CLI): OpenJDK 11/17/21, cloud-readiness y BC4J en `.konveyor/hub-profiles/`.

### Análisis con MTA CLI (también desde Dev Spaces)

Cada target genera su propio HTML en `mta-output/<target>/static-report/index.html`. Entrada siempre: `sample-app/` (Java 8). Las conversiones en `solutions/` son el resultado operativo, no la fuente del análisis.

**1. Terminal de Dev Spaces** (o local con Podman/Docker opcional; por defecto va en modo containerless):

```bash
cd ${PROJECT_SOURCE:-$(pwd)}
# Red Hat CLI (recomendado). En Windows local, con el zip ya descargado:
#   bash scripts/install-mta-cli.sh "$HOME/Downloads/mta-8.3.0-cli-windows-amd64.zip"
# Si ya está extraído en .tools/mta-cli/:
bash scripts/install-mta-cli.sh
export PATH="$PWD/.tools/bin:$PATH"
mta-cli version
```

Si tenés el binario oficial de Red Hat, podés saltar el install y usar `MTA_CLI_URL` o un `mta-cli` ya en el `PATH`. El script de install usa Kantra upstream como fallback abierto.

**2. Un reporte por target** — mismos pasos en Dev Spaces (menú **Run Task** / comandos del `devfile.yaml`) o en la terminal:

| Reporte | Qué mide | Comando CLI / task Dev Spaces |
|---|---|---|
| OpenJDK 11 | APIs removidas o cambiadas hacia 11 (`sun.misc`, JAXB, …) | `bash scripts/mta-cli-analyze.sh openjdk11` · task **MTA report OpenJDK 11** |
| OpenJDK 17 | Hallazgos hacia 17 (p. ej. `Thread.stop`, `Date` deprecado) | `bash scripts/mta-cli-analyze.sh openjdk17` · task **MTA report OpenJDK 17** |
| OpenJDK 21 | Hallazgos hacia 21 (p. ej. `new URL(String)`) | `bash scripts/mta-cli-analyze.sh openjdk21` · task **MTA report OpenJDK 21** |
| cloud-readiness | Aptitud a contenedores (filesystem, localhost, logs) | `bash scripts/mta-cli-analyze.sh cloud-readiness` · task **MTA report cloud-readiness** |
| BC4J | Certificar ADF/BC4J en el JDK e imagen WebLogic (**sin** migrar de servidor) | `bash scripts/mta-cli-analyze.sh bc4j` · task **MTA report BC4J** |

Equivalente manual (sin el wrapper), útil si ya tenés `mta-cli` en el PATH:

```bash
# OpenJDK 11
mta-cli analyze --input sample-app --output mta-output/openjdk11 --target openjdk11 --mode source-only --overwrite

# OpenJDK 17
mta-cli analyze --input sample-app --output mta-output/openjdk17 --target openjdk17 --mode source-only --overwrite

# OpenJDK 21
mta-cli analyze --input sample-app --output mta-output/openjdk21 --target openjdk21 --mode source-only --overwrite

# Cloud readiness
mta-cli analyze --input sample-app --output mta-output/cloud-readiness --target cloud-readiness --mode source-only --overwrite

# BC4J (reglas custom en rules/bc4j)
mta-cli analyze --input sample-app --output mta-output/bc4j --target bc4j --rules rules/bc4j --mode source-only --overwrite
```

**3. Los cinco de una vez:**

```bash
bash scripts/mta-cli-analyze.sh all
# o task Dev Spaces: MTA reports all targets
```

**4. Abrir el HTML:** en Dev Spaces, clic derecho sobre `mta-output/<target>/static-report/index.html` → Open With → Preview / Simple Browser. En local: abrí ese archivo en el navegador.

**5. Extensión MTA (UI):** además del CLI, en Dev Spaces podés elegir el perfil en `.konveyor/hub-profiles/` (`openjdk11`, `openjdk17`, `openjdk21`, `cloud-readiness`, `bc4j`, o `java-containers` para todos juntos) y lanzar el análisis desde la vista Migration Toolkit for Applications.

Guía oficial CLI: [Using the MTA command-line interface](https://docs.redhat.com/en/documentation/migration_toolkit_for_applications/8.1/html/using_the_migration_toolkit_for_applications_command-line_interface/index).

## Qué mide el esfuerzo

El informe suma `effort` por incidente:

- Reglas de producto OpenJDK / cloud-readiness
- Reglas BC4J custom (certificar ADF en el JDK y en la imagen de WebLogic contenedorizada)

El número **no** mide un cambio de servidor de aplicaciones.

## Developer Lightspeed (opcional)

Lightspeed no se activa en el `Tackle` de este chart (`kai_llm_proxy_enabled: false`). En Dev Spaces el workspace deja activo `mta-core.genai.agentMode` (`.vscode/settings.json`) y el proveedor `cpu-qwen` de `.konveyor/provider-settings.yaml` (Qwen2.5-Coder en el Knative Service de este cluster, bearer `mta-demo`). El `postStart` reescribe `baseURL` con la Route `mta-llm` del cluster.

## Valores útiles del chart

```yaml
git:
  uri: https://github.com/maximilianoPizarro/demo-mta-java.git
  ref: main
  appPath: sample-app
  rulesPath: rules/bc4j
app:
  enabled: true
  build:
    enabled: true
solutions:
  enabled: true          # Routes mta-java-11 / 17 / 21
mta:
  enabled: true          # false en Developer Sandbox
  subscription:
    enabled: false       # true con make deploy / Helm manual del operador
  targets:
    - openjdk11
    - openjdk17
    - openjdk21
    - cloud-readiness
    - bc4j
```

## Seguridad

No guardes tokens de `oc login` en el repositorio. Usá `OC_TOKEN` en la sesión. Si un token se filtró, revocalo y generá uno nuevo.
