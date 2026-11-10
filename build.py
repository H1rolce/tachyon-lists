#!/usr/bin/env python3
"""Собирает lists.json — каталог списков Tachyon Lists для ядра steer (splify2 / Zapret Manager).

Берёт актуальный индекс категорий из репозитория Dushnilin/tachyon-lists (release/catalog.json)
и формирует манифест lists.json со ссылками на скомпилированные наборы .srs.
"""

import json
import os
import re
import sys
import urllib.request
from datetime import datetime, timezone

ROOT = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(ROOT, "lists.json")

REPO = os.environ.get("GITHUB_REPOSITORY", "H1rolce/tachyon-lists")
BRANCH = os.environ.get("GITHUB_REF_NAME", "main")
BASE_URL = f"https://raw.githubusercontent.com/{REPO}/{BRANCH}/lists"

SOURCE_REPO = "Dushnilin/tachyon-lists"
SOURCE_TITLE = "Tachyon Lists"
CATALOG_URL = f"https://raw.githubusercontent.com/{SOURCE_REPO}/main/release/catalog.json"
SRS_BASE_URL = f"https://raw.githubusercontent.com/{SOURCE_REPO}/main/release/sing-box"
PREFIX = "tachyon"


def clean_name(raw_title: str, lid: str) -> str:
    if not raw_title or not raw_title.strip():
        return lid
    m = re.match(r"^(.*?)\s+[-—]\s+(.*)$", raw_title)
    if m:
        short = m.group(1).strip()
        if 0 < len(short) < 50:
            return short
    return raw_title.strip()


def fetch_catalog() -> dict:
    req = urllib.request.Request(CATALOG_URL, headers={"User-Agent": "tachyon-steer-catalog/1.0"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode("utf-8"))


def main() -> int:
    catalog = fetch_catalog()
    cats = []
    doms = []

    for item in catalog.get("lists", []):
        lid = item["id"]
        title = item.get("title") or lid
        counts = item.get("counts") or {}

        dom_count = int(counts.get("domain", 0)) + int(counts.get("domain_suffix", 0))
        cidr_count = int(counts.get("ipv4_cidr", 0)) + int(counts.get("ipv6_cidr", 0))

        has_dom = dom_count > 0
        has_cidr = cidr_count > 0

        name_ru = clean_name(title, lid)
        srs_url = f"{SRS_BASE_URL}/{lid}.srs"
        cat_id = f"{PREFIX}:{lid}"

        if has_cidr:
            cats.append({
                "id": cat_id,
                "name_ru": name_ru,
                "file": f"{PREFIX}/{lid}.srs.lst",
                "format": "srs",
                "url": srs_url,
                "tag": "main",
                "source": SOURCE_REPO,
                "source_name": SOURCE_TITLE,
                "default_on": False,
            })

        if has_dom:
            dom_id = f"svc_{PREFIX}_{lid}" if has_cidr else cat_id
            dom_entry = {
                "id": dom_id,
                "kind": "domains",
                "name_ru": name_ru,
                "file": f"{PREFIX}/domains/{lid}.srs.lst",
                "format": "srs",
                "url": srs_url,
                "tag": "main",
                "source": SOURCE_REPO,
                "source_name": SOURCE_TITLE,
                "default_on": False,
                "count": dom_count,
            }
            if has_cidr:
                dom_entry["same_as_ip"] = [cat_id]
            doms.append(dom_entry)

    now = datetime.now(timezone.utc)
    out = {
        "version": now.strftime("%Y-%m-%d_%H-%M"),
        "generated_at": now.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "base_url": BASE_URL,
        "categories": cats,
        "domain_lists": doms,
    }

    keep = lambda d: {k: v for k, v in d.items() if k not in ("version", "generated_at")}
    if os.path.exists(OUT):
        try:
            with open(OUT, encoding="utf-8") as f:
                old = json.load(f)
            if old and keep(old) == keep(out):
                print(f"изменений нет — lists.json не тронут ({old.get('version', '?')})")
                return 0
        except Exception:
            pass

    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"lists.json обновлён: подсетей {len(cats)}, доменов {len(doms)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
