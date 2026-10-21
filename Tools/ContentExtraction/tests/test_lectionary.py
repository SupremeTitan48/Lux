"""The lectionary tables read from the 1693 printing (TCP A28758)."""

import json
import unittest
from pathlib import Path

from lux_extract.build import MAPS, WITNESS
from lux_extract.lectionary import Books, build_lectionary, dominical_letter, parse_psalms, parse_reading, roman


def ref(book, chapter, verse=None, to_chapter=None, to_verse=None):
    return (book, chapter, verse, to_chapter, to_verse)


def shape(text, current=None):
    readings = parse_reading(text, Books(), current)
    return [(r.book, r.chapter, r.verse, r.to_chapter, r.to_verse) for r in readings] if readings else None


class ReferenceTests(unittest.TestCase):
    def test_printed_shapes(self):
        self.assertEqual(shape("Gen. 1"), [ref("Genesis", 1)])
        self.assertEqual(shape("3", "Genesis"), [ref("Genesis", 3)])
        self.assertIsNone(shape("3"))
        self.assertEqual(shape("23, 24.", "Numbers"), [ref("Numbers", 23, None, 24)])
        self.assertEqual(shape("Lu. 1 to 39"), [ref("Luke", 1, None, None, 39)])
        self.assertEqual(shape("1. 39", "Luke"), [ref("Luke", 1, 39)])
        self.assertEqual(shape("Acts 2. v. 22."), [ref("Acts", 2, 22)])
        self.assertEqual(shape("Iſai. 7. ver. 10. to ver. 17."), [ref("Isaiah", 7, 10, None, 17)])
        self.assertEqual(shape("Gen. 22. to v. 20"), [ref("Genesis", 22, None, None, 20)])
        self.assertEqual(shape("9 to verſ. 20", "Genesis"), [ref("Genesis", 9, None, None, 20)])
        self.assertEqual(shape("Wiſ. 5, to v. 17."), [ref("Wisdom", 5, None, None, 17)])
        self.assertEqual(shape("Acts 6. verſ. 8. and ch. 7. to verſ. 30."), [ref("Acts", 6, 8, 7, 30)])
        self.assertEqual(shape("Heb. 11. v. 33. &c. 12. to v. 7."), [ref("Hebrews", 11, 33, 12, 7)])
        self.assertEqual(shape("Jud. v. 6. to v. 16."), [ref("Jude", 1, 6, None, 16)])
        self.assertEqual(shape("Philem."), [ref("Philemon", 1)])
        self.assertEqual(shape("2, 3 John"), [ref("2 John", 1), ref("3 John", 1)])
        self.assertEqual(shape("1. John 4. to v. 14."), [ref("1 John", 4, None, None, 14)])

    def test_rejects_impossible_chapters(self):
        self.assertIsNone(shape("Joel 4"))
        self.assertIsNone(shape("Philem. 2"))

    def test_roman_numerals(self):
        self.assertEqual([roman(n) for n in ("ii", "xix", "xlv", "lxxxix", "cxviij", "cxliii", "lxxxviii")],
                         [2, 19, 45, 89, 118, 143, 88])
        self.assertEqual(parse_psalms("Pſal. xix. xlv. lxxxv."), [19, 45, 85])

    def test_dominical_letters(self):
        self.assertEqual(dominical_letter(1, 1), "A")
        self.assertEqual(dominical_letter(1, 8), "A")
        self.assertEqual(dominical_letter(3, 1), "d")
        self.assertEqual(dominical_letter(12, 31), "A")
        self.assertEqual(dominical_letter(2, 29), "")


class LectionaryContentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        sources = json.loads((WITNESS / "sources.json").read_text(encoding="utf-8"))["sources"]
        meta = next(s for s in sources if s.get("role") == "lectionary")
        cls.content, cls.review = build_lectionary(meta, WITNESS / meta["file"], MAPS)
        cls.kalendar = {(d["month"], d["day"]): d for d in cls.content["kalendar"]}
        cls.sundays = {r["observance"]: r for r in cls.content["sundays"]}
        cls.holy = {r["observance"]: r for r in cls.content["holyDays"]}

    def refs(self, lesson):
        return [(r["book"], r["startChapter"], r.get("startVerse"), r.get("endChapter"), r.get("endVerse"))
                for r in lesson["references"]]

    def test_every_day_of_the_kalendar(self):
        self.assertEqual(len(self.kalendar), 366)
        self.assertIn((2, 29), self.kalendar)

    def test_kalendar_golden_days(self):
        jan2 = self.kalendar[(1, 2)]
        self.assertEqual(self.refs(jan2["morning"]["first"]), [("Genesis", 1, None, None, None)])
        self.assertEqual(self.refs(jan2["morning"]["second"]), [("Matthew", 1, None, None, None)])
        self.assertEqual(self.refs(jan2["evening"]["first"]), [("Genesis", 2, None, None, None)])
        self.assertEqual(self.refs(jan2["evening"]["second"]), [("Romans", 1, None, None, None)])
        # The footnote limits Exodus 6 on 30 January.
        self.assertEqual(self.refs(self.kalendar[(1, 30)]["morning"]["first"]), [("Exodus", 6, 1, None, 13)])
        # Luke 1 divided between 17 and 18 February.
        self.assertEqual(self.refs(self.kalendar[(2, 17)]["morning"]["second"]), [("Luke", 1, 1, None, 38)])
        self.assertEqual(self.refs(self.kalendar[(2, 18)]["morning"]["second"]), [("Luke", 1, 39, None, None)])
        dec31 = self.kalendar[(12, 31)]
        self.assertEqual(self.refs(dec31["morning"]["first"]), [("Isaiah", 65, None, None, None)])
        self.assertEqual(self.refs(dec31["evening"]["first"]), [("Isaiah", 66, None, None, None)])
        self.assertEqual(self.refs(dec31["evening"]["second"]), [("Jude", 1, None, None, None)])

    def test_kalendar_blank_only_on_holy_days(self):
        blank = {(m, d) for (m, d), day in self.kalendar.items()
                 for office in ("morning", "evening") for which in ("first", "second") if day[office][which] is None}
        self.assertEqual(len(blank), 24)
        self.assertIn((11, 30), blank)  # St Andrew
        self.assertIn((2, 24), blank)  # St Matthias

    def test_courses_read_in_order(self):
        # Each course of second lessons reads every chapter of its books at
        # least once a year; Revelation is read only in proper lessons.
        seen = {}
        for day in self.content["kalendar"]:
            for office in ("morning", "evening"):
                lesson = day[office]["second"]
                if lesson:
                    for r in lesson["references"]:
                        seen.setdefault(r["book"], set()).add(r["startChapter"])
        self.assertNotIn("Revelation", seen)
        for book in ("Matthew", "Mark", "Luke", "John", "Acts", "Romans", "Hebrews"):
            chapters = Books().chapters[book]
            self.assertEqual(seen[book], set(range(1, chapters + 1)), book)

    def test_proper_lessons(self):
        self.assertEqual(len(self.sundays), 56)
        self.assertEqual(len(self.holy), 33)
        andrew = self.holy["andrew"]
        self.assertEqual(self.refs(andrew["morning"]["first"]), [("Proverbs", 20, None, None, None)])
        self.assertEqual(self.refs(andrew["evening"]["first"]), [("Proverbs", 21, None, None, None)])
        self.assertNotIn("second", andrew["morning"])
        easter = self.sundays["easter"]
        self.assertEqual(self.refs(easter["morning"]["second"]), [("Romans", 6, None, None, None)])
        self.assertEqual(self.refs(easter["evening"]["second"]), [("Acts", 2, 22, None, None)])
        # A bare number continues the book above it in the same column.
        self.assertEqual(self.refs(self.sundays["trinity-26"]["morning"]["first"]), [("Proverbs", 17, None, None, None)])
        self.assertEqual(self.refs(self.holy["matthias"]["morning"]["first"]), [("Wisdom", 19, None, None, None)])
        self.assertEqual(self.refs(self.holy["annunciation"]["evening"]["first"]), [("Ecclesiasticus", 3, None, None, None)])
        self.assertEqual(self.refs(self.sundays["trinity-22"]["morning"]["first"]), [("Proverbs", 2, None, None, None)])
        christmas = self.holy["christmas"]
        self.assertEqual(self.refs(christmas["morning"]["second"]), [("Luke", 2, 1, None, 14)])
        self.assertEqual(christmas["morning"]["second"]["printed"], "Luk. 2. to ver. 15")
        self.assertIsNone(self.holy["wednesday-before-easter"]["evening"]["second"])

    def test_proper_psalms(self):
        psalms = {r["observance"]: (r["morning"]["psalms"], r["evening"]["psalms"]) for r in self.content["properPsalms"]}
        self.assertEqual(psalms["christmas"], ([19, 45, 85], [89, 110, 132]))
        self.assertEqual(psalms["easter"], ([2, 57, 111], [113, 114, 118]))
        self.assertEqual(set(psalms), {"christmas", "ash-wednesday", "good-friday", "easter", "ascension", "whitsunday"})

    def test_corrections_are_reported(self):
        kinds = [r["kind"] for r in self.review]
        self.assertEqual(kinds.count("tcp-reading-corrected"), 7)
        corrected = self.kalendar[(9, 1)]["morning"]["first"]
        self.assertEqual(corrected["printed"], "Hoſ. 1")
        self.assertEqual(corrected["provenance"]["review"], "tcp-reading-corrected")
        self.assertEqual(self.refs(corrected), [("Hosea", 14, None, None, None)])


if __name__ == "__main__":
    unittest.main()
