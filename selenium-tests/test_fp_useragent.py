#!/usr/bin/python
import tbbtest


class Test(tbbtest.TBBTest):
    def test_useragent(self):
        driver = self.driver
        js = driver.execute_script
        # Check that useragent string is as expected
        # We better know the ESR version we're testing
        self.assertEqual("Mozilla/5.0 (Windows NT 6.1; rv:24.0) Gecko/20100101 Firefox/24.0",
                         js("return navigator.userAgent"))
