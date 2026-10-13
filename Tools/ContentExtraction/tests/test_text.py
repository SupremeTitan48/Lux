import unittest

from lux_extract.text import collapse, restore_initial


class RestoreInitialTests(unittest.TestCase):
    def test_spaced_small_capitals(self):
        self.assertEqual(restore_initial("L M I G H T Y and moſt merciful", "A"), "ALMIGHTY and moſt merciful")

    def test_closed_capitals(self):
        self.assertEqual(restore_initial("EARLY beloved", "D"), "DEARLY beloved")

    def test_whole_word_letter(self):
        self.assertEqual(restore_initial("Lord, open thou our lips.", "O"), "O Lord, open thou our lips.")

    def test_punctuation_after_spaced_word(self):
        self.assertEqual(restore_initial("R A N T , O Lord", "G"), "GRANT, O Lord")

    def test_close_up_only(self):
        self.assertEqual(restore_initial("AL M I G H T Y God", ""), "ALMIGHTY God")

    def test_collapse(self):
        self.assertEqual(collapse(" a\n  b\tc "), "a b c")


if __name__ == "__main__":
    unittest.main()
