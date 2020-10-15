from marionette_harness import MarionetteTestCase

class Test(MarionetteTestCase):
    def test_plugins(self):
        with self.marionette.using_context('content'):
            self.marionette.navigate('about:robots')
            js = self.marionette.execute_script
            # Check that plugins are disabled
            self.assertEqual(True, js("return navigator.plugins.length === 0"))
            self.assertEqual(True, js("return navigator.mimeTypes.length === 0"))
