import hashlib
import json

from marionette_harness import MarionetteTestCase

class Test(MarionetteTestCase):
    def test_fp_fonts(self):
        m = self.marionette
        with m.using_context('content'):
            m.set_pref("network.proxy.allow_hijacking_localhost", False)
            m.navigate(self.marionette.absolute_url("fonts/fonts.html"))
            fonts = m.find_element('id', 'fonts-list').text.strip()
            glyphs = m.find_element('id', 'glyphs').text.strip()

        font_list = set(json.loads(fonts))
        bundled_fonts = set([
            "Arimo",
            "Cousine",
            "Noto Emoji",
            "Noto Naskh Arabic",
            "Noto Sans Armenian",
            "Noto Sans Bengali",
            "Noto Sans Buginese",
            "Noto Sans Canadian Aboriginal",
            "Noto Sans Cherokee",
            "Noto Sans Devanagari",
            "Noto Sans Ethiopic",
            "Noto Sans Georgian",
            "Noto Sans Gujarati",
            "Noto Sans Gurmukhi",
            "Noto Sans Hebrew",
            "Noto Sans JP Regular",
            "Noto Sans Kannada",
            "Noto Sans Khmer",
            "Noto Sans KR Regular",
            "Noto Sans Lao",
            "Noto Sans Malayalam",
            "Noto Sans Mongolian",
            "Noto Sans Myanmar",
            "Noto Sans Oriya",
            "Noto Sans SC Regular",
            "Noto Sans Sinhala",
            "Noto Sans Tamil",
            "Noto Sans TC Regular",
            "Noto Sans Telugu",
            "Noto Sans Thaana",
            "Noto Sans Thai",
            "Noto Sans Tibetan",
            "Noto Sans Yi",
            "Noto Serif Armenian",
            "Noto Serif Khmer",
            "Noto Serif Lao",
            "Noto Serif Thai",
            "STIX Math",
            "Tinos",
            "Twemoji Mozilla",
        ])
        self.assertEqual(font_list, bundled_fonts)

        glyphs_hash = hashlib.sha256(glyphs.encode('utf-8')).hexdigest()
        expected_hash = "5e185a7bd097ecf482fd6a4d8228a9e25974cfbb4bc5f07751b9d09bdebc0f67"
        self.assertEqual(glyphs_hash, expected_hash)
