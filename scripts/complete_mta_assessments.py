#!/usr/bin/env python3
"""Complete Pathfinder assessments and print Hub module summary."""
import base64
import copy
import json
import ssl
import sys
import urllib.error
import urllib.request

HUB = sys.argv[1]
AUTH = base64.b64encode(b"admin:admin").decode()
CTX = ssl._create_unverified_context()


def req(method, path, data=None):
    url = f"https://{HUB}/hub/{path}"
    body = None if data is None else json.dumps(data).encode()
    request = urllib.request.Request(url, data=body, method=method)
    request.add_header("Authorization", f"Basic {AUTH}")
    if body is not None:
        request.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(request, context=CTX) as resp:
            raw = resp.read().decode()
            return resp.status, (json.loads(raw) if raw else None)
    except urllib.error.HTTPError as exc:
        return exc.code, exc.read().decode(errors="replace")


def get(path):
    code, data = req("GET", path)
    if code >= 400:
        raise RuntimeError(f"GET {path} -> {code}: {data}")
    return data


def answer_questionnaire(questionnaire):
    sections = copy.deepcopy(questionnaire.get("sections") or [])
    for section in sections:
        for question in section.get("questions") or []:
            answers = question.get("answers") or []
            chosen = None
            for risk in ("green", "yellow", "red"):
                for ans in answers:
                    if ans.get("risk") == risk:
                        chosen = ans
                        break
                if chosen:
                    break
            if not chosen and answers:
                chosen = answers[0]
            for ans in answers:
                ans["selected"] = ans is chosen
    return sections


q = get("questionnaires/1")
# Reports > Current landscape reads application.risk. Hub only copies a
# completed assessment onto the application when the questionnaire is required.
if not q.get("required"):
    q["required"] = True
    code, _ = req("PUT", "questionnaires/1", q)
    print(f"questionnaire required -> {code}")
    q = get("questionnaires/1")
apps = get("applications")
existing = get("assessments")
by_app = {(a.get("application") or {}).get("id"): a for a in existing}
print("existing assessments for apps:", sorted(by_app))

for app in apps:
    aid = app["id"]
    sections = answer_questionnaire(q)
    if aid in by_app:
        assessment = by_app[aid]
        assessment["sections"] = sections
        assessment["stakeholders"] = [{"id": 1, "name": "Ana Arquitecta"}]
        code, data = req("PUT", f"assessments/{assessment['id']}", assessment)
        print(f"PUT assessment app={aid} -> {code}")
        continue

    payload = {
        "questionnaire": {"id": 1, "name": q["name"]},
        "application": {"id": aid, "name": app["name"]},
        "sections": sections,
        "stakeholders": [{"id": 1, "name": "Ana Arquitecta"}],
        "stakeholderGroups": [{"id": 1, "name": "Equipo Modernizacion"}],
    }
    code, data = req("POST", f"applications/{aid}/assessments", payload)
    print(f"POST applications/{aid}/assessments -> {code} {str(data)[:160]}")

archs = get("archetypes")
if archs:
    arch = archs[0]
    payload = {
        "questionnaire": {"id": 1, "name": q["name"]},
        "archetype": {"id": arch["id"], "name": arch["name"]},
        "sections": answer_questionnaire(q),
        "stakeholders": [{"id": 1, "name": "Ana Arquitecta"}],
    }
    code, data = req("POST", f"archetypes/{arch['id']}/assessments", payload)
    print(f"POST archetypes/{arch['id']}/assessments -> {code} {str(data)[:160]}")

print("\n=== MODULE SUMMARY ===")
for label in [
    "applications",
    "businessservices",
    "stakeholders",
    "stakeholdergroups",
    "jobfunctions",
    "migrationwaves",
    "reviews",
    "archetypes",
    "assessments",
    "analyses",
    "questionnaires",
    "targets",
    "generators",
]:
    try:
        data = get(label)
        print(f"{label}: {len(data)}")
    except Exception as exc:
        print(f"{label}: ERROR {exc}")

print("\n=== APPLICATIONS ===")
for app in get("applications"):
    print(
        f"- {app['id']} {app['name']}: effort={app.get('effort')} "
        f"risk={app.get('risk')} assessed={app.get('assessed')} "
        f"tags={len(app.get('tags') or [])} "
        f"bs={(app.get('businessService') or {}).get('name')}"
    )

print("\n=== ANALYZER TASKS ===")
for task in get("tasks"):
    if task.get("kind") == "analyzer" and not (task.get("data") or {}).get(
        "mode", {}
    ).get("discovery"):
        print(
            f"- {task['id']} {task.get('name')}: {task.get('state')} "
            f"app={(task.get('application') or {}).get('name')}"
        )

print(f"\nHUB_UI=https://{HUB}")
print("login: admin / admin")
