#!/usr/bin/python
import tbbtest


class Test(tbbtest.TBBTest):
    def test_plugins(self):
        driver = self.driver
        js = driver.execute_script
        # Check that plugins are disabled
        self.assertEqual(True, js("return navigator.plugins.length === 0"))
        self.assertEqual(True, js("return navigator.mimeTypes.length === 0"))