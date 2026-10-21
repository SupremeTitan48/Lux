"""Generate the structured BCP 1662 content package.

Output layout, relative to ``Traditions/BCP1662``. Runtime content, bundled
with the Swift package, under ``Sources/BCP1662/Resources/Content``::

    manifest.json                 file list with SHA-256, source checksum
    psalter.json                  150 Psalms, pointed, and the 30-day course
    collects.json                 collects and governing rubrics, 84 observances
    services/morning-prayer.json  the Order for Morning Prayer
    services/evening-prayer.json  the Order for Evening Prayer
    services/athanasian-creed.json  Quicunque vult, for its appointed feasts
    propers/easter-anthems.json   the Easter Day anthems (instead of Venite)
    rubrics/general.json          how the Psalter and Scripture are read
    lectionary/lessons.json       the Kalendar's lessons, the Proper Lessons and
                                  Proper Psalms (from the 1693 printing, see
                                  lectionary.py)

Provenance, kept in the repository but not shipped, under ``Provenance``::

    transcription/normalized.txt  every normalized line with raw line and page
    transcription/edits.jsonl     every normalization edit, one per line
    editorial-log.json            summary of the edits by rule
    review-queue.json             everything a person should check against
                                  the printed page

Every output is deterministic: the same source and tables give the same bytes,
which is what ``lux_extract check`` relies on.
"""

from __future__ import annotations

import collections
import hashlib
import json
from pathlib import Path

from . import decisions as dec
from .collects import extract_collects, extract_notes
from .lectionary import build_lectionary
from .normalize import normalize
from .offices import extract_service
from .psalter import parse_psalter

TOOL_DIR = Path(__file__).resolve().parent.parent
MAPS = TOOL_DIR / "maps"
DATA = TOOL_DIR / "data"
WITNESS = TOOL_DIR.parents[1] / "Traditions" / "BCP1662" / "Witness"

CONTENT_SCHEMA_VERSION = 1
CONTENT_VERSION = "0.1.0"

# Readings preserved exactly as printed that a reviewer should confirm
# against the PDF. They are reported, never corrected.
SOURCE_ODDITIES = [
    {"find": "In Quires an Places", "note": "Probably 'and' lost in extraction or print; preserved."},
    {"find": "who has made all men", "note": "Good Friday third collect reads 'has' where later printings read 'hast'; preserved."},
    {"find": "relfect", "note": "Apparent transposition of 'reflect'; preserved."},
    {"find": "throug-out", "note": "Hyphenation or letter loss; preserved."},
    {"find": "Laudamuſ", "note": "Long s at word end; preserved."},
]


def _dump(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")


def _psalter_json(psalter, source_id: str) -> dict:
    psalms: dict[int, dict] = {}
    for block in psalter.blocks:
        entry = psalms.setdefault(block.psalm, {"number": block.psalm, "incipit": None, "verses": []})
        offset = 0
        if block.portion is not None:
            entry.setdefault("portions", [])
            offset = 8 * (block.portion - 1)
            entry["portions"].append({
                "portion": block.portion,
                "incipit": block.incipit,
                "firstVerse": offset + 1,
                "lastVerse": offset + len(block.verses),
                "provenance": {"rawLines": [block.raw_start, block.raw_end], "extractionPages": sorted(block.pages)},
            })
            if entry["incipit"] is None:
                entry["incipit"] = block.incipit
        else:
            entry["incipit"] = block.incipit
            entry["provenance"] = {"rawLines": [block.raw_start, block.raw_end], "extractionPages": sorted(block.pages)}
        for verse in block.verses:
            first, second = verse.halves()
            v = {"n": offset + verse.number}
            if block.portion is not None:
                v["printed"] = verse.number
            if second is None:
                v["text"] = first
            else:
                v["first"], v["second"] = first, second
            v["rawLine"] = verse.raw_line
            entry["verses"].append(v)
    course = []
    for half in psalter.course:
        if half.office == "morning":
            course.append({"day": half.day})
        refs = []
        for block in half.blocks:
            ref = {"psalm": block.psalm}
            if block.portion is not None:
                ref["portion"] = block.portion
                ref["verses"] = [8 * (block.portion - 1) + 1, 8 * (block.portion - 1) + len(block.verses)]
            refs.append(ref)
        course[-1][half.office] = {"psalms": refs, "rawLine": half.raw_line}
    return {
        "schemaVersion": CONTENT_SCHEMA_VERSION,
        "source": source_id,
        "translation": "Coverdale (Great Bible), as printed in the 1662 Book of Common Prayer",
        "psalms": [psalms[n] for n in sorted(psalms)],
        "course": course,
    }


RUNTIME_DIR = Path("Sources/BCP1662/Resources/Content")
PROVENANCE_DIR = Path("Provenance")


def build(source, meta: dict, root: Path) -> dict:
    out = root / RUNTIME_DIR
    prov_out = root / PROVENANCE_DIR
    ligatures = dec.decisions(dec.load_table(dec.LIGATURES_PATH))
    joins = dec.decisions(dec.load_table(dec.JOINS_PATH))
    spaces = json.loads((DATA / "spaces.json").read_text(encoding="utf-8"))["edits"]
    dropcaps = json.loads((DATA / "dropcaps.json").read_text(encoding="utf-8"))
    text = normalize(source, ligatures, joins, spaces)
    source_id = meta["id"]

    review: list[dict] = []

    psalter = parse_psalter(text.lines, dropcaps)
    _dump(out / "psalter.json", _psalter_json(psalter, source_id))
    review += [{"area": "psalter", **i} for i in psalter.issues]

    services = {}
    for name, rel in (("morning_prayer", "services/morning-prayer.json"),
                      ("evening_prayer", "services/evening-prayer.json"),
                      ("athanasian_creed", "services/athanasian-creed.json"),
                      ("general_rubrics", "rubrics/general.json"),
                      ("easter_anthems", "propers/easter-anthems.json")):
        service, issues = extract_service(text.lines, MAPS / f"{name}.json")
        service = {"schemaVersion": CONTENT_SCHEMA_VERSION, "source": source_id, **{k: v for k, v in service.items() if k != "source"}}
        _dump(out / rel, service)
        services[name] = service
        review += [{"area": service["id"], **i} for i in issues]
        for unit in service["units"]:
            prov = unit.get("provenance", {})
            if prov.get("review") or prov.get("dropcap"):
                review.append({"area": service["id"], "kind": prov.get("review") or "dropcap-" + prov["dropcap"],
                               "unit": unit["id"], "rawLines": prov["rawLines"]})

    observances, issues = extract_collects(text.lines, MAPS / "collects.json", dropcaps)
    _dump(out / "collects.json", {"schemaVersion": CONTENT_SCHEMA_VERSION, "source": source_id,
                                   "notes": extract_notes(text.lines, MAPS / "collects.json"), "observances": observances})
    # Drop capitals on Epistle and Gospel openings are not resolved because
    # those texts are not yet extracted; keep only issues touching collects.
    collect_lines = {c["provenance"]["rawLines"][0] for o in observances for c in o["collects"]}
    for i in issues:
        if i["kind"] in ("dropcap-unresolved", "dropcap-mismatch"):
            sites = i.get("sites", [i.get("rawLine")])
            if not collect_lines.intersection(sites):
                continue
        review.append({"area": "collects", **i})

    sources = json.loads((WITNESS / "sources.json").read_text(encoding="utf-8"))["sources"]
    lectionary_source = next(s for s in sources if s.get("role") == "lectionary")
    lectionary, issues = build_lectionary(lectionary_source, WITNESS / lectionary_source["file"], MAPS)
    _dump(out / "lectionary" / "lessons.json", {"schemaVersion": CONTENT_SCHEMA_VERSION, **lectionary})
    review += issues

    # Transcription with line-level traceability.
    with_marks = []
    for line in text.lines:
        flag = "D" if line.dropcaps else ("H" if line.head else " ")
        with_marks.append(f"r{line.raw_start:05d}-{line.raw_end:05d} p{line.page:03d} {flag} {line.text.rstrip()}")
    (prov_out / "transcription").mkdir(parents=True, exist_ok=True)
    (prov_out / "transcription" / "normalized.txt").write_text(
        "# Normalized transcription of " + meta["file"] + " (sha256 " + meta["sha256"] + ")\n"
        "# Columns: raw line range, extraction page, flag (D = displaced drop capitals, H = running head), text\n"
        + "\n".join(with_marks) + "\n", encoding="utf-8")
    with (prov_out / "transcription" / "edits.jsonl").open("w", encoding="utf-8") as fh:
        for e in text.events:
            fh.write(json.dumps({"rule": e.rule, "rawLine": e.raw_line, "before": e.before, "after": e.after,
                                 **({"note": e.note} if e.note else {})}, ensure_ascii=False) + "\n")

    by_rule = collections.Counter(e.rule for e in text.events)
    _dump(prov_out / "editorial-log.json", {
        "schemaVersion": CONTENT_SCHEMA_VERSION,
        "source": source_id,
        "policy": "Documentation/TRANSCRIPTION_POLICY.md",
        "editsByRule": dict(sorted(by_rule.items())),
        "detail": "transcription/edits.jsonl",
        "decisionTables": {
            "ligatures": _table_summary(dec.LIGATURES_PATH),
            "joins": _table_summary(dec.JOINS_PATH),
            "dropcaps": {"entries": len(dropcaps), "byBasis": dict(sorted(collections.Counter(v["basis"] for v in dropcaps.values()).items()))},
            "spaces": {"entries": sum(len(v) for v in spaces.values())},
        },
    })

    for odd in SOURCE_ODDITIES:
        line = next((l for l in text.lines if odd["find"] in l.text), None)
        if line is None:
            raise RuntimeError(f"source oddity no longer found: {odd['find']!r}")
        review.append({"area": "source", "kind": "reading-preserved", "text": odd["find"], "note": odd["note"], "rawLine": line.raw_start})
    for name, path in (("ligatures", dec.LIGATURES_PATH), ("joins", dec.JOINS_PATH)):
        for key, entry in sorted(dec.load_table(path).items()):
            if entry.get("basis") in ("ambiguous", "unknown"):
                review.append({"area": "decision-table", "kind": f"{name}-{entry['basis']}", "key": key,
                               "decision": entry["decision"], "example": entry.get("example", "")})
    review.append({"area": "content", "kind": "not-extracted",
                   "note": "The Calendar with the Table of Lessons, the Proper Lessons and Proper Psalms, the tables of movable feasts and the Table of Vigils are absent from the supplied text extraction. The lessons and Proper Psalms are taken from the 1693 printing (TCP A28758) and need checking against the Baskerville pages; the feast tables and the Table of Vigils are not yet used."})
    review.append({"area": "content", "kind": "not-extracted",
                   "note": "Epistles and Gospels are located but not yet extracted."})
    _dump(prov_out / "review-queue.json", {"schemaVersion": CONTENT_SCHEMA_VERSION, "source": source_id,
                                       "counts": dict(sorted(collections.Counter(r["kind"] for r in review).items())),
                                       "items": review})

    files = sorted(p for p in out.rglob("*") if p.is_file() and p.name != "manifest.json")
    provenance_files = sorted(p for p in prov_out.rglob("*") if p.is_file())
    manifest = {
        "schemaVersion": CONTENT_SCHEMA_VERSION,
        "tradition": "bcp1662",
        "contentVersion": CONTENT_VERSION,
        "title": "The Book of Common Prayer (1662), Baskerville printing of 1762",
        "source": {"id": source_id, "file": meta["file"], "sha256": meta["sha256"]},
        "additionalSources": [{"id": lectionary_source["id"], "file": lectionary_source["file"],
                               "sha256": lectionary_source["sha256"], "role": lectionary_source["role"]}],
        "files": [{"path": str(p.relative_to(out)), "sha256": hashlib.sha256(p.read_bytes()).hexdigest()} for p in files],
        "provenance": [{"path": str(PROVENANCE_DIR / p.relative_to(prov_out)), "sha256": hashlib.sha256(p.read_bytes()).hexdigest()}
                       for p in provenance_files],
    }
    _dump(out / "manifest.json", manifest)
    return {
        "lines": len(text.lines),
        "pages": text.page_count,
        "psalms": len({b.psalm for b in psalter.blocks}),
        "collectObservances": len(observances),
        "serviceUnits": {k: len(v["units"]) for k, v in services.items()},
        "kalendarDays": len(lectionary["kalendar"]),
        "properLessonDays": len(lectionary["sundays"]) + len(lectionary["holyDays"]),
        "reviewItems": len(review),
        "reviewByKind": dict(sorted(collections.Counter(r["kind"] for r in review).items())),
    }


def _table_summary(path: Path) -> dict:
    table = dec.load_table(path)
    return {"entries": len(table), "byBasis": dict(sorted(collections.Counter(v.get("basis", "?") for v in table.values()).items()))}
