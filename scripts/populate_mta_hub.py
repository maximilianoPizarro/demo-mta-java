#!/usr/bin/env python3
"""Populate MTA Hub modules for the demo (inventory, controls, waves, analyses)."""
import base64
import json
import ssl
import sys
import urllib.error
import urllib.request
from datetime import date, timedelta

HUB_HOST = sys.argv[1] if len(sys.argv) > 1 else ""
if not HUB_HOST:
    raise SystemExit("usage: populate_mta_hub.py <hub-host>")

GIT_URL = "https://github.com/maximilianoPizarro/demo-mta-java.git"
AUTH = base64.b64encode(b"admin:admin").decode()
CTX = ssl._create_unverified_context()


def req(method, path, data=None):
    url = f"https://{HUB_HOST}/hub/{path}"
    body = None if data is None else json.dumps(data).encode()
    request = urllib.request.Request(url, data=body, method=method)
    request.add_header("Authorization", f"Basic {AUTH}")
    if body is not None:
        request.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(request, context=CTX) as resp:
            raw = resp.read().decode()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode(errors="replace")
        raise RuntimeError(f"{method} {path} -> {exc.code}: {detail}") from exc


def get(path):
    return req("GET", path)


def post(path, data):
    return req("POST", path, data)


def put(path, data):
    return req("PUT", path, data)


def ensure_named(collection_path, name, payload, key="name"):
    existing = {item[key]: item for item in get(collection_path)}
    if name in existing:
        return existing[name]
    created = post(collection_path, payload)
    print(f"created {collection_path}: {name} id={created.get('id')}")
    return created


bss = {}
for name, desc in [
    ("Retail Banking", "Canales y core bancario legados"),
    ("Corporate Systems", "Sistemas corporativos WebLogic / Java"),
]:
    bss[name] = ensure_named(
        "businessservices", name, {"name": name, "description": desc}
    )

jfs = {j["name"]: j for j in get("jobfunctions")}
for name in [
    "Arquitecto de Modernizacion",
    "Lider Tecnico Java",
    "Product Owner",
]:
    if name not in jfs:
        jfs[name] = post("jobfunctions", {"name": name})
        print(f"created jobfunction: {name}")

sgs = {}
for name, desc in [
    ("Equipo Modernizacion", "Owners de la iniciativa MTA"),
    ("Aplicaciones Legacy", "Equipos de apps WebLogic"),
]:
    sgs[name] = ensure_named(
        "stakeholdergroups", name, {"name": name, "description": desc}
    )

sts = {s["name"]: s for s in get("stakeholders")}
for name, email, jf, groups in [
    (
        "Ana Arquitecta",
        "ana.arquitecta@example.com",
        "Arquitecto de Modernizacion",
        ["Equipo Modernizacion"],
    ),
    (
        "Juan Tech Lead",
        "juan.lead@example.com",
        "Lider Tecnico Java",
        ["Aplicaciones Legacy", "Equipo Modernizacion"],
    ),
    (
        "Lucia PO",
        "lucia.po@example.com",
        "Product Owner",
        ["Equipo Modernizacion"],
    ),
]:
    if name not in sts:
        sts[name] = post(
            "stakeholders",
            {
                "name": name,
                "email": email,
                "jobFunction": {"id": jfs[jf]["id"], "name": jf},
                "stakeholderGroups": [
                    {"id": sgs[g]["id"], "name": g} for g in groups
                ],
            },
        )
        print(f"created stakeholder: {name}")

# Refresh maps after creates
bss = {b["name"]: b for b in get("businessservices")}
sts = {s["name"]: s for s in get("stakeholders")}
sgs = {g["name"]: g for g in get("stakeholdergroups")}
apps = {a["name"]: a for a in get("applications")}

wanted_apps = [
    {
        "name": "demo-mta-java",
        "description": (
            "Demo Java 8 / WebLogic: esfuerzo OpenJDK 11/17/21 + "
            "cloud-readiness (servidor no se migra)."
        ),
        "repository": {
            "kind": "git",
            "url": GIT_URL,
            "branch": "main",
            "path": "sample-app",
        },
        "businessService": "Corporate Systems",
        "owner": "Juan Tech Lead",
        "comments": "Targets: openjdk11/17/21 + cloud-readiness + reglas BC4J. Sin EAP/Quarkus.",
    },
    {
        "name": "customer-tomcat-legacy",
        "description": "Ejemplo Konveyor Tomcat — aptitud a contenedores.",
        "repository": {
            "kind": "git",
            "url": "https://github.com/konveyor/example-applications.git",
            "branch": "main",
            "path": "example-1",
        },
        "businessService": "Retail Banking",
        "owner": "Ana Arquitecta",
        "comments": "Analisis cloud-readiness de referencia.",
    },
    {
        "name": "weblogic-inventory-svc",
        "description": "Servicio de inventario simulado en WebLogic/Java 8.",
        "repository": {
            "kind": "git",
            "url": "https://github.com/konveyor/example-applications.git",
            "branch": "main",
            "path": "example-1",
        },
        "businessService": "Corporate Systems",
        "owner": "Juan Tech Lead",
        "comments": "Incluido para poblar inventory y migration wave.",
    },
]

for item in wanted_apps:
    bs = bss[item["businessService"]]
    owner = sts[item["owner"]]
    payload = {
        "name": item["name"],
        "description": item["description"],
        "repository": item["repository"],
        "comments": item["comments"],
        "businessService": {"id": bs["id"], "name": bs["name"]},
        "owner": {"id": owner["id"], "name": owner["name"]},
        "contributors": [{"id": sts["Lucia PO"]["id"], "name": "Lucia PO"}],
    }
    if item["name"] in apps:
        existing = apps[item["name"]]
        payload["id"] = existing["id"]
        payload["tags"] = existing.get("tags") or []
        apps[item["name"]] = put(f"applications/{payload['id']}", payload)
        print(f"updated application: {item['name']} id={payload['id']}")
    else:
        apps[item["name"]] = post("applications", payload)
        print(
            f"created application: {item['name']} id={apps[item['name']].get('id')}"
        )

apps = {a["name"]: a for a in get("applications")}

waves = {w["name"]: w for w in get("migrationwaves")}
wave_name = "Wave 1 - Java & Containers"
if wave_name not in waves:
    start = date.today().strftime("%Y-%m-%dT00:00:00Z")
    end = (date.today() + timedelta(days=90)).strftime("%Y-%m-%dT00:00:00Z")
    waves[wave_name] = post(
        "migrationwaves",
        {
            "name": wave_name,
            "startDate": start,
            "endDate": end,
            "applications": [
                {"id": a["id"], "name": a["name"]} for a in apps.values()
            ],
            "stakeholders": [
                {"id": sts["Ana Arquitecta"]["id"], "name": "Ana Arquitecta"}
            ],
            "stakeholderGroups": [
                {
                    "id": sgs["Equipo Modernizacion"]["id"],
                    "name": "Equipo Modernizacion",
                }
            ],
        },
    )
    print(f"created migrationwave id={waves[wave_name].get('id')}")
else:
    print(f"migrationwave exists: {wave_name}")

# Reviews (application review questionnaire lite)
for app in apps.values():
    if app.get("review"):
        continue
    try:
        review = post(
            "reviews",
            {
                "application": {"id": app["id"], "name": app["name"]},
                "proposedAction": "refactor",
                "effortEstimate": "Medium",
                "businessCriticality": 3,
                "workPriority": 2,
                "comments": (
                    "Priorizar OpenJDK y cloud-readiness; no cambiar WebLogic."
                ),
            },
        )
        print(f"created review for {app['name']} id={review.get('id')}")
    except RuntimeError as exc:
        print(f"review skipped for {app['name']}: {exc}")

# Archetype
archs = {a["name"]: a for a in get("archetypes")}
arch_name = "Java WebLogic Legacy"
if arch_name not in archs:
    java_tags = [t for t in get("tags") if t.get("name") == "Java"][:1]
    try:
        archs[arch_name] = post(
            "archetypes",
            {
                "name": arch_name,
                "description": (
                    "Apps Java en WebLogic a evaluar para OpenJDK y contenedores"
                ),
                "comments": "No implica cambio de servidor de aplicaciones",
                "tags": [{"id": t["id"], "name": t["name"]} for t in java_tags],
                "stakeholders": [
                    {
                        "id": sts["Ana Arquitecta"]["id"],
                        "name": "Ana Arquitecta",
                    }
                ],
                "stakeholderGroups": [
                    {
                        "id": sgs["Equipo Modernizacion"]["id"],
                        "name": "Equipo Modernizacion",
                    }
                ],
            },
        )
        print(f"created archetype id={archs[arch_name].get('id')}")
    except RuntimeError as exc:
        print(f"archetype skipped: {exc}")

# Analyzer tasks
tasks = get("tasks")
targets = [
    "konveyor.io/target=openjdk11",
    "konveyor.io/target=openjdk17",
    "konveyor.io/target=openjdk21",
    "konveyor.io/target=cloud-readiness",
]


def is_migration_analyzer(task):
    if task.get("addon") != "analyzer" or task.get("kind") != "analyzer":
        return False
    data = task.get("data") or {}
    mode = data.get("mode") or {}
    if mode.get("discovery"):
        return False
    name = task.get("name") or ""
    if "discovery" in name:
        return False
    return True


for name, app in apps.items():
    aid = app["id"]
    existing = [
        t
        for t in tasks
        if t.get("application", {}).get("id") == aid and is_migration_analyzer(t)
    ]
    active = [
        t
        for t in existing
        if t.get("state")
        in (
            "Created",
            "Ready",
            "Pending",
            "QuotaBlocked",
            "Postponed",
            "Running",
            "Succeeded",
        )
    ]
    if active:
        print(f"analyzer already present for {name}: {[t['id'] for t in active]}")
        continue
    task = post(
        "tasks",
        {
            "name": f"{name}.analyzer",
            "kind": "analyzer",
            "addon": "analyzer",
            "application": {"id": aid},
            "data": {
                "mode": {"binary": False, "withDeps": True, "artifact": ""},
                "tagger": {"enabled": True},
                "verbosity": 0,
                "scope": {
                    "withKnownLibs": False,
                    "packages": {"included": [], "excluded": []},
                },
                "targets": [],
                "sources": [],
                "rules": {
                    "path": "",
                    "labels": {
                        "included": targets
                        + (
                            ["konveyor.io/target=bc4j"]
                            if name == "demo-mta-java"
                            else []
                        ),
                        "excluded": [],
                    },
                    **(
                        {
                            "repository": {
                                "kind": "git",
                                "url": GIT_URL,
                                "branch": "main",
                                "path": "rules/bc4j",
                            }
                        }
                        if name == "demo-mta-java"
                        else {}
                    ),
                },
            },
        },
    )
    # Hub leaves new analyzer tasks in Created until explicitly Ready.
    if task.get("id") and task.get("state") == "Created":
        task["state"] = "Ready"
        task = put(f"tasks/{task['id']}", task)
    print(
        f"submitted analyzer for {name}: id={task.get('id')} state={task.get('state')}"
    )

print("DONE")
