# Demo MTA: esfuerzo Java 8 a 11/17/21 y aptitud a contenedores, sin cambiar WebLogic

[![Open in Dev Spaces](https://img.shields.io/badge/Open%20in-Dev%20Spaces-EE0000?style=for-the-badge&logo=redhat&logoColor=white)](https://github.com/maximilianoPizarro/demo-mta-java#dev-spaces)

Demo sintética con [Migration Toolkit for Applications](https://developers.redhat.com/products/mta/download): mide el esfuerzo de pasar de Java 8 a OpenJDK 11, 17 y 21 y la aptitud a contenedores. WebLogic se queda como servidor de aplicaciones. El análisis certifica el JDK y la imagen contenedorizada; los targets son `openjdk11`, `openjdk17`, `openjdk21`, `cloud-readiness` y `bc4j`.

**Reportes MTA (GitHub Pages):** [comparación de los cinco targets](https://maximilianopizarro.github.io/demo-mta-java/mta-reports/) — misma `sample-app` Java 8, reportes Konveyor sanitizados y tabla de incidentes / story points.

La fuente del análisis es siempre `sample-app/` (Java 8). `solutions/java11`, `solutions/java17` y `solutions/java21` son conversiones operativas acumulativas: muestran el código ya llevado a ese JDK. Cloud-readiness y BC4J quedan como deuda de certificación también en esas conversiones.

## Análisis con MTA

Cada target genera un HTML propio. El informe suma el campo `effort` de cada incidente (story points). Ese número estima el trabajo de llegar a ese target sobre el código Java 8. Los cinco reportes se calculan por separado sobre la misma app: la suma de los cinco no es un único plan de migración.

Snapshot publicado (`docs/mta-reports/summaries.json`, MTA CLI 8.3.0, modo `source-only`, 2026-09-30):

| Target | Qué mide | Incidentes | Story points |
|---|---|---:|---:|
| [OpenJDK 11](https://maximilianopizarro.github.io/demo-mta-java/mta-reports/openjdk11/) | APIs removidas o cambiadas hacia 11 (`sun.misc`, módulos Java EE que salen del JDK, JAXB) | 13 | 15 |
| [OpenJDK 17](https://maximilianopizarro.github.io/demo-mta-java/mta-reports/openjdk17/) | Lo anterior más deprecaciones hacia 17 (Security Manager, Applets, `Thread.stop`, `Date`) | 18 | 38 |
| [OpenJDK 21](https://maximilianopizarro.github.io/demo-mta-java/mta-reports/openjdk21/) | Lo anterior más APIs hacia 21 (`new URL(String)`, charset UTF-8 por defecto) | 27 | 51 |
| [cloud-readiness](https://maximilianopizarro.github.io/demo-mta-java/mta-reports/cloud-readiness/) | Aptitud a contenedores: filesystem local, localhost, IP fija, sockets, logs | 24 | 64 |
| [BC4J](https://maximilianopizarro.github.io/demo-mta-java/mta-reports/bc4j/) | Certificar ADF/BC4J en el JDK y en la imagen WebLogic. El ruleset custom está en `rules/bc4j` | 22 | 63 |

La app de ejemplo trae a propósito una matriz de Issues repartida en varias clases, no un solo archivo:

| Área | Dónde está en `sample-app` |
|---|---|
| `sun.misc.Unsafe` y `sun.misc.BASE64` | `LegacyUnsafeDemo`, `LegacyEncoding` |
| Módulos que salen del JDK (`javax.activation`, `javax.annotation`, JAXB) | `JavaxEeApisDemo`, `XmlBindingDemo` |
| Security Manager, Applets, `Subject.doAs`, `finalize` | `SecurityManagerDemo`, `AppletLegacyDemo`, `ModernJdkDeprecations` |
| `Thread.stop`, `Date` deprecado, `new URL(String)` | `DeprecatedApis` |
| Localhost, IP fija, filesystem, sockets / RMI | `CloudLocalhostClients`, `EmbeddedSocketProbe`, `FileLogger`, `HardcodedNetwork`, `LocalFilesystem`, `LegacyRemoteProbe` |
| ADF/BC4J (`ApplicationModuleImpl`, `EntityImpl`, `ViewObjectImpl`, `.jpx`, `.xcfg`) | `Bc4jApplicationModule`, `Bc4jCustomerEntity`, `Bc4jOrderView`, `src/main/resources/` |

Reglas de producto OpenJDK y cloud-readiness vienen con el CLI. BC4J es un ruleset del repo (`rules/bc4j/ruleset.yaml` + `bc4j-rules.yaml`): detecta el footprint ADF para estimar certificación de JDK e imagen. El mensaje de cada regla deja WebLogic como servidor.

Perfiles listos para la extensión y para el Hub: `.konveyor/hub-profiles/` (`openjdk11`, `openjdk17`, `openjdk21`, `cloud-readiness`, `bc4j`, y `java-containers` para lanzarlos juntos).

### Conversiones operativas

| Ruta | JDK | Qué resuelve respecto de `sample-app` |
|---|---|---|
| `solutions/java11/` | 11 (UBI8 OpenJDK 11) | Base64 estándar, JAXB explícito y ajustes de cloud-readiness de ese salto |
| `solutions/java17/` | 17 | Acumulativa: además Date y `Thread.stop` |
| `solutions/java21/` | 21 (UBI9 OpenJDK 21) | Acumulativa: además `URI` en lugar de `new URL(String)` |

Esas carpetas no son la entrada del análisis. Después de cambiar `sample-app`, regenerá los reportes con `make analyze-all && make publish-reports`.

## Descargar el CLI

El binario oficial se baja del sitio de Red Hat Developer (cuenta Red Hat). En la página, elegí **Migration Toolkit CLI** — el zip de análisis de aplicaciones — para tu sistema. El **Ops CLI** de la misma página es otra herramienta.

- Descargas (Linux, macOS y Windows, x86_64 y aarch64, más el zip de fuentes): [developers.redhat.com/products/mta/download](https://developers.redhat.com/products/mta/download)
- Producto: [Migration Toolkit for Applications en Red Hat Developer](https://developers.redhat.com/products/mta/overview)
- Instalar el CLI desde el zip: [Installing the MTA command-line interface](https://docs.redhat.com/en/documentation/migration_toolkit_for_applications/8.1/html/installing_the_migration_toolkit_for_applications/installing-mta-cli_installing-mta-title)
- Usar `analyze` y leer el reporte: [Using the MTA command-line interface](https://docs.redhat.com/en/documentation/migration_toolkit_for_applications/8.1/html/using_the_migration_toolkit_for_applications_command-line_interface/index)

El archivo sigue el nombre `mta-<versión>-cli-<os>-<arch>.zip` (por ejemplo `mta-8.2.1-cli-linux-amd64.zip`, `mta-8.2.1-cli-windows-amd64.zip`, `mta-8.2.1-cli-darwin-arm64.zip`). La comparación publicada de este repo se generó con CLI **8.3.0**; para reproducir esos HTML usá un CLI de esa línea o regenerá con la versión que acabás de bajar.

La misma página de descargas lista el operador (consola Hub en OpenShift) y los plugins de IDE. La extensión de VS Code que usa Dev Spaces es `redhat.mta-vscode-extension`.

### Instalar el zip en este repo

El script deja un wrapper en `.tools/bin/mta-cli` que entra al bundle antes de ejecutar, para que resuelvan `jdtls`, rulesets y el static report. El zip pesa varios cientos de MiB.

```bash
# Zip descargado desde developers.redhat.com
bash scripts/install-mta-cli.sh "$HOME/Downloads/mta-8.2.1-cli-linux-amd64.zip"
# Windows (Git Bash), mismo flujo:
# bash scripts/install-mta-cli.sh "$HOME/Downloads/mta-8.2.1-cli-windows-amd64.zip"

export PATH="$PWD/.tools/bin:$PATH"
mta-cli version
```

Si ya extrajiste el zip en `.tools/mta-cli/`, `bash scripts/install-mta-cli.sh` solo escribe el wrapper. También acepta `MTA_CLI_ZIP` o `MTA_CLI_URL` apuntando al archivo. Sin zip, el script cae a Kantra upstream (más chico, sin el bundle completo de Red Hat). Preferí el zip de Developer.

## Correr los cinco reportes

Desde la raíz del repo, con `mta-cli` en el `PATH`:

| Reporte | Comando | Task de Dev Spaces |
|---|---|---|
| OpenJDK 11 | `bash scripts/mta-cli-analyze.sh openjdk11` | **MTA report OpenJDK 11** |
| OpenJDK 17 | `bash scripts/mta-cli-analyze.sh openjdk17` | **MTA report OpenJDK 17** |
| OpenJDK 21 | `bash scripts/mta-cli-analyze.sh openjdk21` | **MTA report OpenJDK 21** |
| cloud-readiness | `bash scripts/mta-cli-analyze.sh cloud-readiness` | **MTA report cloud-readiness** |
| BC4J | `bash scripts/mta-cli-analyze.sh bc4j` | **MTA report BC4J** |
| Los cinco | `bash scripts/mta-cli-analyze.sh all` | **MTA reports all targets** |

Atajos de `make`: `analyze-openjdk11`, `analyze-openjdk17`, `analyze-openjdk21`, `analyze-cloud`, `analyze-bc4j`, `analyze-all`. Cada uno llama antes a `install-mta-cli`.

Equivalente directo (el target `bc4j` necesita `--rules rules/bc4j`):

```bash
mta-cli analyze --input sample-app --output mta-output/openjdk11 --target openjdk11 --mode source-only --overwrite
mta-cli analyze --input sample-app --output mta-output/openjdk17 --target openjdk17 --mode source-only --overwrite
mta-cli analyze --input sample-app --output mta-output/openjdk21 --target openjdk21 --mode source-only --overwrite
mta-cli analyze --input sample-app --output mta-output/cloud-readiness --target cloud-readiness --mode source-only --overwrite
mta-cli analyze --input sample-app --output mta-output/bc4j --target bc4j --rules rules/bc4j --mode source-only --overwrite
```

Salida: `mta-output/<target>/static-report/index.html`. El reporte es una SPA y necesita HTTP.

```bash
python3 -m http.server 8765 --directory mta-output/openjdk11/static-report
# http://127.0.0.1:8765/
```

En Dev Spaces: clic derecho sobre ese `index.html` → Open With → Preview / Simple Browser. Desde la extensión, elegí el perfil en `.konveyor/hub-profiles/` y lanzá el análisis en la vista Migration Toolkit for Applications.

### Publicar la comparación

`make publish-reports` copia los cinco `static-report` a `docs/mta-reports/` (assets Konveyor deduplicados, rutas `file://` saneadas, `summaries.json` y el índice). El workflow `.github/workflows/pages.yml` publica `docs/` en GitHub Pages al pushear `main`.

```bash
bash scripts/mta-cli-analyze.sh all   # si hace falta refrescar
make publish-reports                  # → docs/mta-reports/
python3 -m http.server 8765 --directory docs
# http://127.0.0.1:8765/mta-reports/
```

URL estable: `https://maximilianopizarro.github.io/demo-mta-java/mta-reports/`

## Dev Spaces

Abrí este repo en el Dev Spaces del cluster:

`https://devspaces.<apps-domain>/#https://github.com/maximilianoPizarro/demo-mta-java`

Al arrancar se instalan las extensiones de `.vscode/extensions.json` y `.che/extensions.json` (`redhat.java`, Maven y `redhat.mta-vscode-extension`). El `postStart` (`scripts/devspaces-setup.sh`) copia `.konveyor/provider-settings.yaml` y reescribe `baseURL` con el host de la Route `mta-llm`. El build de la sample usa JDK 8 (`scripts/with-java8.sh`). Si el workspace ya estaba abierto, detenerlo y volver a entrar para que tome el `devfile.yaml`.

En la terminal del workspace:

```bash
cd ${PROJECT_SOURCE:-$(pwd)}
bash scripts/install-mta-cli.sh    # o pasale el zip de Developer si lo tenés
export PATH="$PWD/.tools/bin:$PATH"
mta-cli version
bash scripts/mta-cli-analyze.sh all
```

### Developer Lightspeed (opcional)

El `Tackle` de este chart deja `kai_llm_proxy_enabled: false`. En el workspace, `.vscode/settings.json` activa `mta-core.genai.agentMode` y `.konveyor/provider-settings.yaml` define el proveedor `cpu-qwen` (Qwen2.5-Coder en el Knative Service del cluster, bearer `mta-demo`). El `postStart` apunta `baseURL` a la Route `mta-llm`.

## Mapa del repositorio

| Ruta | Rol |
|------|-----|
| `sample-app/` | App Maven Java 8: entrada de todos los análisis |
| `solutions/java11/` `java17/` `java21/` | Conversiones operativas (no son la fuente del reporte) |
| `rules/bc4j/` | Ruleset custom de certificación ADF/BC4J |
| `.konveyor/hub-profiles/` | Perfiles por reporte para la extensión y el Hub |
| `scripts/install-mta-cli.sh` | Instala el zip de Developer (o Kantra si no hay zip) en `.tools/bin` |
| `scripts/mta-cli-analyze.sh` | Un análisis por target, o `all` |
| `docs/mta-reports/` | Comparación publicada en GitHub Pages |
| `reports/` | HTML de story points para el sandbox (Route `mta-effort-report`) |
| `devfile.yaml` | Workspace Dev Spaces con Java y la extensión MTA |
| `charts/mta-demo/` | Helm de la app, las tres conversiones y el operador MTA (OpenShift) |
| `examples/aks/` | Pipeline de Azure DevOps que genera el reporte MTA y lo publica en AKS |
| `examples/bootstrap/` | Entrypoint RHDP: Subscription del patterns-operator y Pattern CR |

## Instalación del chart en OpenShift

Esta sección despliega la demo en el cluster. El análisis de la sección anterior corre en local o en Dev Spaces y no depende de este chart.

Un solo cluster, sin spokes y sin GPU. El Pattern CR de escenario A está en `examples/pattern-cr/hub-only-cpu.yaml`.

| Pieza | Chart | Qué hace |
|---|---|---|
| MTA | `charts/mta-demo` | Operador, Hub, app Java 8 y Routes de las conversiones 11/17/21 |
| Dev Spaces | `charts/devspaces` | IDE en el browser sobre este repo |
| Serverless | `charts/openshift-serverless` | Knative Serving |
| Inferencia CPU | `charts/cpu-inference` | Qwen2.5-Coder-7B con tool calling, escala desde cero |

### RHDP Field Content

Pedido Field Content CI:

| Campo | Valor |
|---|---|
| Repositorio | `https://github.com/maximilianoPizarro/demo-mta-java.git` |
| Branch | `main` |
| GitOps path | **`examples/bootstrap`** |
| Workers (AWS) | **2 × m5a.4xlarge** (16 vCPU / 64 Gi) |
| OpenShift AI / AAP | desmarcados |
| Modelo catálogo | `granite-3-2-8b-instruct` (fallback; la demo usa Qwen en el cluster) |
| Users | 1 |

`examples/bootstrap` instala el Validated Patterns Operator y el Pattern CR. `main` ya incluye ese entrypoint.

### Requisitos

- `oc`, `helm` 3.x
- Cluster OpenShift
- **Ciclo completo (app + consola MTA):** usuario con `cluster-admin` (OLM crea CRDs)
- **Solo app (Developer Sandbox):** sin admin; `mta.enabled=false`
- Repo Git público alcanzable por el cluster, o build binario local

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

Si ambos responden `yes`, `make deploy` instala MTA, Serverless, Dev Spaces y el modelo CPU (y activa las Subscriptions):

```bash
make deploy
```

Solo el chart de la demo, con el operador MTA:

```bash
helm upgrade --install mta-demo ./charts/mta-demo \
  -n mta-demo --create-namespace \
  --set mta.subscription.enabled=true \
  --set git.uri=https://github.com/maximilianoPizarro/demo-mta-java.git \
  --set git.ref=main
```

GitOps, con el Validated Patterns Operator ya instalado:

```bash
oc apply -f examples/pattern-cr/hub-only-cpu.yaml
```

Si responden `no` (Developer Sandbox), la consola Hub del operador no se puede instalar: hace falta `cluster-admin`. Red Hat publica esa UI con el Operator, no como chart aparte. En sandbox queda la Route del reporte de esfuerzo (`mta-effort-report`).

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

### 3. Repo Git

El chart apunta a `https://github.com/maximilianoPizarro/demo-mta-java.git` (`sample-app` para el análisis, `rules/bc4j` para las reglas custom). El Hub clona ese repo público; no hace falta un token de GitHub.

Si el cluster no puede clonar:

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
- **Reporte de esfuerzo (HTML):** `oc get route mta-effort-report -n <namespace>`
- **Consola MTA Hub:** solo con `mta.enabled=true` y cluster-admin. Route `*ui*` / `*mta*`. Login: `admin` / `admin`
- Targets del Hub: `openjdk11`, `openjdk17`, `openjdk21`, `cloud-readiness`, `bc4j`

### Valores útiles del chart

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

## Ejemplo: Azure DevOps hacia AKS

El pipeline no construye `sample-app` ni empuja una imagen. Corre el CLI de MTA sobre `sample-app`, arma la comparación de los cinco targets y la publica en AKS con el nginx de `examples/aks/report.yaml`.

| Archivo | Rol |
|---|---|
| `examples/aks/azure-pipelines.yml` | Análisis MTA, artefacto `mta-reports` y copia al cluster |
| `examples/aks/namespace.yaml` | Namespace `mta-demo` |
| `examples/aks/report.yaml` | PVC, nginx público y Service `LoadBalancer` para el HTML |

En el proyecto de Azure DevOps, creá el pipeline desde el YAML existente y apuntá a `examples/aks/azure-pipelines.yml`. Hace falta:

1. El zip **Migration Toolkit CLI** (Linux x86_64) de [developers.redhat.com/products/mta/download](https://developers.redhat.com/products/mta/download), cargado como Secure file con el nombre `mta-cli.zip` y autorizado para el pipeline.
2. Service connection **Azure Resource Manager** con el nombre literal `azure-mta-demo` y rol de usuario del cluster.
3. En el YAML, `aksResourceGroup` y `aksClusterName` del AKS de destino.
4. Environment `aks-demo` si querés una aprobación antes de publicar el reporte.

El nombre de la connection va escrito en el YAML: Azure DevOps lo autoriza al compilar el pipeline. El agente corre `mta-cli analyze` para `openjdk11`, `openjdk17`, `openjdk21`, `cloud-readiness` y `bc4j`, después `publish-mta-reports.sh`. Cada corrida también deja el artefacto `mta-reports` para descargarlo desde Azure DevOps.

Después del deploy, el Service `mta-effort-report` expone la comparación:

```bash
kubectl get svc mta-effort-report -n mta-demo
# http://<EXTERNAL-IP>/
```

## Seguridad

No guardes tokens de `oc login` en el repositorio. Usá `OC_TOKEN` en la sesión. Si un token se filtró, revocalo y generá uno nuevo.
