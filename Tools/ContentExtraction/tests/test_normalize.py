import unittest
from pathlib import Path

from lux_extract.normalize import PUA_AMBIGUOUS, PUA_CT, PUA_ST, UnresolvedDecision, join_key, ligature_key, normalize
from lux_extract.raw import RawLine, RawSource


def source(*lines):
    """Build a RawSource; a None entry is an LF-only page break."""
    raw = []
    for i, text in enumerate(lines, start=1):
        raw.append(RawLine(i, "", False) if text is None else RawLine(i, text, True))
    return RawSource(Path("synthetic"), "0" * 64, tuple(raw))


class NormalizeTests(unittest.TestCase):
    def test_soft_hyphen_removed(self):
        text = normalize(source("ever\x02lasting"), {}, {})
        self.assertEqual(text.lines[0].text, "everlasting")

    def test_long_s_line_is_joined_by_table(self):
        src = source("we be", "ſeech thee", "and", "ſo forth")
        joins = {join_key("be", "ſeech"): "join", join_key("and", "ſo"): "space"}
        text = normalize(src, {}, joins)
        self.assertEqual([l.text for l in text.lines], ["we beſeech thee", "and ſo forth"])
        self.assertEqual(text.lines[0].raw_start, 1)
        self.assertEqual(text.lines[0].raw_end, 2)
        self.assertEqual((text.lines[1].raw_start, text.lines[1].raw_end), (3, 4))
        self.assertEqual([e.rule for e in text.events], ["line-join"])

    def test_unknown_join_is_refused(self):
        with self.assertRaises(UnresolvedDecision):
            normalize(source("a", "ſb"), {}, {})

    def test_page_break_is_not_joined(self):
        src = source("end of page", None, "ſtart of next")
        text = normalize(src, {}, {})
        self.assertEqual(len(text.lines), 2)
        self.assertEqual([l.page for l in text.lines], [1, 2])
        self.assertEqual(text.page_count, 2)

    def test_unambiguous_ligatures(self):
        text = normalize(source(f"a{PUA_CT}s and fir{PUA_ST} things"), {}, {})
        self.assertEqual(text.lines[0].text, "acts and first things")

    def test_ambiguous_ligature_uses_table(self):
        word = f"Chri{PUA_AMBIGUOUS}"
        text = normalize(source(f"Jesus {word} our Lord"), {ligature_key(word): "st"}, {})
        self.assertEqual(text.lines[0].text, "Jesus Christ our Lord")

    def test_unresolved_ambiguous_ligature_is_refused(self):
        with self.assertRaises(UnresolvedDecision):
            normalize(source(f"Chri{PUA_AMBIGUOUS}"), {}, {})


if __name__ == "__main__":
    unittest.main()
