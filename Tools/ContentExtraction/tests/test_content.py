"""Invariants and golden passages of the generated BCP 1662 content.

These run against the real source witness, so they also guard the checked-in
decision tables and maps.
"""

import json
import tempfile
import unittest
from pathlib import Path

from lux_extract.__main__ import TRADITION, _source
from lux_extract.build import RUNTIME_DIR, build


class GeneratedContentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.root = Path(cls.tmp.name)
        cls.out = cls.root / RUNTIME_DIR
        source, meta = _source()
        cls.report = build(source, meta, cls.root)

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def load(self, rel):
        return json.loads((self.out / rel).read_text(encoding="utf-8"))

    def test_committed_content_is_current(self):
        for path in self.root.rglob("*"):
            if path.is_file():
                rel = path.relative_to(self.root)
                self.assertEqual(path.read_bytes(), (TRADITION / rel).read_bytes(), f"{rel} is stale")

    def test_page_count_matches_witness(self):
        self.assertEqual(self.report["pages"], 339)

    def test_psalter_shape(self):
        psalter = self.load("psalter.json")
        self.assertEqual([p["number"] for p in psalter["psalms"]], list(range(1, 151)))
        ps119 = psalter["psalms"][118]
        self.assertEqual(len(ps119["portions"]), 22)
        self.assertEqual([v["n"] for v in ps119["verses"]], list(range(1, 177)))
        self.assertEqual(len(psalter["course"]), 30)
        for day in psalter["course"]:
            self.assertTrue(day["morning"]["psalms"] and day["evening"]["psalms"])
        # Every Psalm (or portion) appears exactly once in the course.
        refs = [(r["psalm"], r.get("portion")) for d in psalter["course"] for o in ("morning", "evening") for r in d[o]["psalms"]]
        self.assertEqual(len(refs), len(set(refs)))
        self.assertEqual(len(refs), 149 + 22)

    def test_psalter_golden(self):
        psalter = self.load("psalter.json")
        ps23 = psalter["psalms"][22]
        self.assertEqual(ps23["incipit"], "Dominus regit me.")
        self.assertEqual(ps23["verses"][0]["first"], "THE Lord is my ſhepherd")
        self.assertEqual(ps23["verses"][0]["second"], "therefore can I lack nothing.")
        day1 = psalter["course"][0]
        self.assertEqual([r["psalm"] for r in day1["morning"]["psalms"]], [1, 2, 3, 4, 5])
        self.assertEqual([r["psalm"] for r in day1["evening"]["psalms"]], [6, 7, 8])

    def test_morning_prayer_golden(self):
        mp = self.load("services/morning-prayer.json")
        ids = [u["id"] for u in mp["units"]]
        for required in ("mp.venite", "mp.tedeum", "mp.benedicite", "mp.benedictus", "mp.jubilate", "mp.creed"):
            self.assertIn(required, ids)
        venite = next(u for u in mp["units"] if u["id"] == "mp.venite")
        self.assertTrue(venite["verses"][0]["first"].startswith("O Come, let us ſing unto the Lord"))
        self.assertEqual(len(venite["gloria"]), 2)
        self.assertEqual(len(next(u for u in self.load("services/evening-prayer.json")["units"] if u["id"] == "ep.nuncdimittis")["gloria"]), 2)

    def test_evening_prayer_golden(self):
        ep = self.load("services/evening-prayer.json")
        ids = [u["id"] for u in ep["units"]]
        for required in ("ep.magnificat", "ep.cantate", "ep.nuncdimittis", "ep.deus"):
            self.assertIn(required, ids)
        nunc = next(u for u in ep["units"] if u["id"] == "ep.nuncdimittis")
        self.assertTrue(nunc["verses"][0]["first"].startswith("LORD, now lettest thou thy ſervant depart in peace"))

    def test_collects_golden(self):
        collects = {o["id"]: o for o in self.load("collects.json")["observances"]}
        self.assertEqual(len(collects), 86)
        self.assertTrue(collects["advent-1"]["collects"][0]["text"].startswith(
            "ALMIGHTY God, give us grace that we may caſt away the works of darkneſs"))
        self.assertEqual(len(collects["good-friday"]["collects"]), 3)
        for o in collects.values():
            for c in o["collects"]:
                self.assertTrue(c["text"].endswith("Amen."), o["id"])

    def test_canticles_have_two_part_gloria(self):
        for rel in ("services/morning-prayer.json", "services/evening-prayer.json", "services/athanasian-creed.json"):
            for unit in self.load(rel)["units"]:
                if unit["kind"] == "canticle" and unit["id"] != "mp.tedeum":
                    self.assertEqual(len(unit.get("gloria", [])), 2, unit["id"])
                    for verse in unit["verses"]:
                        self.assertIn("first", verse, (unit["id"], verse))

    def test_canticle_verse_counts(self):
        counts = {u["id"]: len(u["verses"]) for rel in ("services/morning-prayer.json", "services/evening-prayer.json")
                  for u in self.load(rel)["units"] if u["kind"] == "canticle"}
        self.assertEqual(counts, {"mp.venite": 11, "mp.tedeum": 29, "mp.benedicite": 32, "mp.benedictus": 12,
                                  "mp.jubilate": 4, "ep.magnificat": 9, "ep.cantate": 10, "ep.nuncdimittis": 4, "ep.deus": 7})
        magnificat = next(u for u in self.load("services/evening-prayer.json")["units"] if u["id"] == "ep.magnificat")
        self.assertEqual(magnificat["verses"][0]["first"], "MY ſoul doth magnify the Lord")

    def test_athanasian_creed(self):
        creed = next(u for u in self.load("services/athanasian-creed.json")["units"] if u["id"] == "ath.creed")
        self.assertEqual(len(creed["verses"]), 42)
        self.assertEqual(creed["verses"][0]["first"], "WHOSOEVER will be ſaved")
        self.assertEqual(creed["verses"][8]["first"], "The Father incomprehenſible, the Son incomprehenſible")
        self.assertEqual(creed["verses"][41]["first"], "This is the Catholick Faith")

    def test_easter_anthems(self):
        anthems = self.load("propers/easter-anthems.json")
        texts = [u["text"] for u in anthems["units"] if u["kind"] == "sentence"]
        self.assertEqual(len(texts), 3)
        self.assertTrue(all(t.startswith("CHRIST") for t in texts))

    def test_manifest_hashes(self):
        import hashlib
        manifest = self.load("manifest.json")
        for entry in manifest["files"]:
            digest = hashlib.sha256((self.out / entry["path"]).read_bytes()).hexdigest()
            self.assertEqual(digest, entry["sha256"], entry["path"])
        for entry in manifest["provenance"]:
            digest = hashlib.sha256((self.root / entry["path"]).read_bytes()).hexdigest()
            self.assertEqual(digest, entry["sha256"], entry["path"])


if __name__ == "__main__":
    unittest.main()
