# Demo MTA: Java 8 a OpenJDK + aptitud a contenedores (WebLogic se queda)

[![Open in Dev Spaces](https://img.shields.io/badge/Open%20in-Dev%20Spaces-EE0000?style=for-the-badge&logo=redhat&logoColor=white)](https://devspaces.apps.ocp.wjwzm.sandbox2915.opentlc.com/#https://github.com/maximilianoPizarro/demo-mta-java)

Demo sintética para medir esfuerzo de actualización de Java (8 a 11/17/21) y aptitud a contenedores con Migration Toolkit for Applications.

El mismo repositorio Git alimenta:

1. El build/deploy de la app de ejemplo (Helm)
2. El análisis de MTA (código en `sample-app`, reglas BC4J en `rules/bc4j`)
3. El workspace de Dev Spaces (IDE + extensión MTA)

## Pattern (hub-only, CPU)

Un solo cluster, sin spokes y sin GPU. El Pattern CR de escenario A está en `examples/pattern-cr/hub-only-cpu.yaml`.

| Pieza | Chart | Qué hace |
|---|---|---|
| MTA | `charts/mta-demo` | Operador, Hub y la app de ejemplo |
| Dev Spaces | `charts/devspaces` | IDE en el browser sobre este repo |
| Serverless | `charts/openshift-serverless` | Knative Serving |
| Inferencia CPU | `charts/cpu-inference` | Qwen2.5-Coder-7B con tool calling, escala desde cero |

En el cluster actual:

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
| `rules/bc4j/` | Ruleset custom (certificación ADF/BC4J, no cambio de servidor) |
| `charts/mta-demo/` | Helm: app + reporte de esfuerzo (Route) + operador MTA Hub (si hay cluster-admin) |
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
oc login --token="$OC_TOKEN" --server=https://api.rm2.thpm.p1.openshiftapps.com:6443
oc whoami
```

### 2. Elegir modo según permisos

```bash
oc auth can-i create subscriptions.operators.coreos.com --all-namespaces
oc auth can-i create customresourcedefinitions.apiextensions.k8s.io
```

Si ambos responden `yes`:

```bash
helm upgrade --install mta-demo ./charts/mta-demo \
  -n mta-demo --create-namespace \
  --set git.uri=https://github.com/maximilianoPizarro/demo-mta-java.git \
  --set git.ref=main
```

Si responden `no` (Developer Sandbox):

```bash
oc project <usuario>-dev
helm upgrade --install mta-demo ./charts/mta-demo \
  -n <usuario>-dev \
  --set mta.enabled=false \
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

- **App:** `oc get route mta-java-demo -n <namespace>`
- **Reporte de esfuerzo (HTML):** `oc get route mta-effort-report -n <namespace>` — story points OpenJDK / cloud-readiness / BC4J
- **Consola MTA Hub (producto):** solo con `mta.enabled=true` + cluster-admin. Route `*ui*` / `*mta*`. Login: `admin` / `admin`
- Targets: `openjdk11`, `openjdk17`, `openjdk21`, `cloud-readiness`, `bc4j`
- **No** se seleccionan EAP, Quarkus ni Open Liberty

## Dev Spaces

El botón **Open in Dev Spaces** abre este repo en el Dev Spaces de este cluster:

`https://devspaces.apps.ocp.wjwzm.sandbox2915.opentlc.com/#https://github.com/maximilianoPizarro/demo-mta-java`

En la extensión MTA, perfil con targets OpenJDK 11/17/21 + cloud-readiness y carpeta de reglas `rules/bc4j`.

## Qué mide el esfuerzo

El informe suma `effort` por incidente:

- Reglas de producto OpenJDK / cloud-readiness
- Reglas BC4J custom (certificar ADF en el JDK y en la imagen de WebLogic contenedorizada)

El número **no** mide un cambio de servidor de aplicaciones.

## Developer Lightspeed (opcional)

Lightspeed no se activa en el `Tackle` de este chart (`kai_llm_proxy_enabled: false`). Si ya tenés un endpoint OpenAI-compatible, en Dev Spaces / VS Code:

1. Command Palette → `MTA: Open the Gen AI model provider configuration file`
2. Configurar `baseURL` `/v1`, modelo y API key
3. Activar Gen AI Agent Mode

Sin ese endpoint, la demo termina en el informe estático de MTA.

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
mta:
  enabled: true          # false en Developer Sandbox
  targets:
    - openjdk11
    - openjdk17
    - openjdk21
    - cloud-readiness
    - bc4j
```

## Seguridad

No guardes tokens de `oc login` en el repositorio. Usá `OC_TOKEN` en la sesión. Si un token se filtró, revocalo y generá uno nuevo.
