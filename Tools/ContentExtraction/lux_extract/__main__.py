"""Command-line entry point.

    python3 -m lux_extract propose   # fill missing decision-table entries
    python3 -m lux_extract build     # regenerate Traditions/BCP1662 and Scripture/KJV content
    python3 -m lux_extract check     # fail if generated content is stale
"""

from __future__ import annotations

import argparse
import json
import sys
import tempfile
from pathlib import Path

from . import decisions as dec
from . import kjv
from .build import PROVENANCE_DIR, RUNTIME_DIR, build
from .normalize import normalize
from .raw import load_raw

REPO = Path(__file__).resolve().parents[3]
TRADITION = REPO / "Traditions" / "BCP1662"
SOURCES_JSON = TRADITION / "Witness" / "sources.json"
KJV = REPO / "Scripture" / "KJV"


def _source():
    meta = json.loads(SOURCES_JSON.read_text(encoding="utf-8"))
    primary = meta["sources"][0]
    return load_raw(SOURCES_JSON.parent / primary["file"], primary["sha256"]), primary


def cmd_propose(args) -> int:
    source, _ = _source()
    lists = [Path(p) for p in args.word_list]
    lexicon = dec.build_lexicon(source, lists)
    joins = dec.load_table(dec.JOINS_PATH)
    print("joins:", dec.propose_joins(source, lexicon, joins))
    dec.save_table(dec.JOINS_PATH, joins)
    text = normalize(source, None, dec.decisions(joins))
    ligatures = dec.load_table(dec.LIGATURES_PATH)
    print("ligatures:", dec.propose_ligatures(source, lexicon, ligatures, [l.text for l in text.lines]))
    dec.save_table(dec.LIGATURES_PATH, ligatures)
    return 0


def cmd_build(args) -> int:
    source, meta = _source()
    root = Path(args.out) if args.out else TRADITION
    report = build(source, meta, root)
    report["kjv"] = kjv.write_package(KJV / "Witness", Path(args.kjv_out) if args.kjv_out else KJV)
    print(json.dumps(report, indent=1))
    return 0


def _stale(generated_root: Path, committed_root: Path, dirs) -> list[str]:
    generated = {p.relative_to(generated_root) for p in generated_root.rglob("*") if p.is_file()}
    committed = {p.relative_to(committed_root) for d in dirs for p in (committed_root / d).rglob("*") if p.is_file()}
    stale = []
    for rel in sorted(generated | committed):
        a, b = generated_root / rel, committed_root / rel
        if not a.exists() or not b.exists() or a.read_bytes() != b.read_bytes():
            stale.append(str(committed_root.relative_to(REPO) / rel))
    return stale


def cmd_check(args) -> int:
    source, meta = _source()
    with tempfile.TemporaryDirectory() as tmp, tempfile.TemporaryDirectory() as kjv_tmp:
        build(source, meta, Path(tmp))
        kjv.write_package(KJV / "Witness", Path(kjv_tmp))
        stale = _stale(Path(tmp), TRADITION, (RUNTIME_DIR, PROVENANCE_DIR))
        stale += _stale(Path(kjv_tmp), KJV, (kjv.RUNTIME_DIR, kjv.PROVENANCE_DIR))
    if stale:
        print("Generated content is stale. Run `python3 -m lux_extract build`.\n" + "\n".join(stale))
        return 1
    print("Generated content is up to date.")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="lux_extract")
    sub = parser.add_subparsers(dest="command", required=True)
    p = sub.add_parser("propose", help="propose missing decision-table entries")
    p.add_argument(
        "--word-list",
        action="append",
        default=["/usr/share/dict/british-english", "/usr/share/dict/american-english"],
        help="plain word lists consulted only for proposals",
    )
    p.set_defaults(func=cmd_propose)
    b = sub.add_parser("build", help="generate structured content")
    b.add_argument("--out", help="tradition root to write into (default: Traditions/BCP1662)")
    b.add_argument("--kjv-out", help="KJV package root to write into (default: Scripture/KJV)")
    b.set_defaults(func=cmd_build)
    c = sub.add_parser("check", help="verify committed content matches a fresh build")
    c.set_defaults(func=cmd_check)
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
