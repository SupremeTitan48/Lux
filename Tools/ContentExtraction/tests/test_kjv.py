"""The King James Version read from the eBible PDF."""

import json
import unittest

from lux_extract import kjv
from lux_extract.__main__ import KJV


class SegmentTests(unittest.TestCase):
    def verse(self, *runs):
        v = kjv.Verse(1, 1)
        line = kjv.Line(1, [])
        for text, italic in runs:
            glyphs = [kjv.Glyph(c, "", 0.0) if c == " " else kjv.Glyph(c, "NotoSerif-Italic" if italic else "NotoSerif-Regular", 12.0)
                      for c in text]
            v.add(glyphs, line)
        v.tidy()
        return v.segments

    def test_spaces_belong_to_the_plain_text(self):
        self.assertEqual(self.verse(("darkness ", False), ("was ", True), ("upon", False)),
                         [["darkness ", False], ["was", True], [" upon", False]])

    def test_lines_join_with_one_space_and_marks_go(self):
        self.assertEqual(self.verse(("the first day.†", False), ("And God", False)),
                         [["the first day. And God", False]])


class KJVContentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        meta = json.loads((KJV / "Witness" / "sources.json").read_text(encoding="utf-8"))["sources"][0]
        lines = kjv.read_pdf(KJV / "Witness" / meta["file"], meta["sha256"])
        cls.content, cls.report = kjv.build_kjv(meta, lines)

    def chapter(self, slug, n):
        return self.content[f"books/{slug}.json"]["chapters"][n - 1]

    def test_every_book_and_verse(self):
        self.assertEqual(len(self.content["index.json"]["books"]), 72)
        self.assertEqual(self.report["verses"], 31372)
        self.assertEqual(self.report["missingVerses"], [])
        self.assertEqual(self.report["layoutIssues"], [])

    def test_supplied_words(self):
        v = self.chapter("genesis", 1)["verses"][1]
        self.assertEqual(v["segments"], ["And the earth was without form, and void; and darkness ", {"supplied": "was"},
                                         " upon the face of the deep. And the Spirit of God moved upon the face of the waters."])

    def test_a_space_pdfium_misses_is_inferred(self):
        v = self.chapter("proverbs", 13)["verses"][11]
        self.assertIn({"supplied": "it is"}, v["segments"])

    def test_footnote_marks_are_left_out(self):
        text = "".join(s if isinstance(s, str) else s["supplied"] for s in self.chapter("genesis", 1)["verses"][3]["segments"])
        self.assertEqual(text, "And God saw the light, that it was good: and God divided the light from the darkness.")

    def test_paragraph_marks_are_kept(self):
        self.assertTrue(self.chapter("genesis", 1)["verses"][5]["segments"][0].startswith("¶ And God said"))

    def test_reviewed_division_of_ecclesiasticus_44(self):
        self.assertEqual(self.chapter("ecclesiasticus", 44)["verseCount"], 23)
        self.assertEqual(len(self.chapter("ecclesiasticus", 44)["verses"]), 23)

    def test_baruch_6_is_the_epistle_of_jeremy(self):
        first = self.chapter("baruch", 6)["verses"][0]["segments"][0]
        self.assertTrue(first.startswith("A copy of an epistle, which Jeremy sent"))


if __name__ == "__main__":
    unittest.main()
