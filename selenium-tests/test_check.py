#!/usr/bin/python
import unittest, time, re
import tbbtest

class CheckTpo(tbbtest.TBBTest):
    def test_check_tpo(self):
        driver = self.driver
        driver.get("http://check.torproject.org/")
        self.assertEqual("Congratulations. This browser is configured to use Tor.", driver.find_element_by_css_selector("h1.on").text)

if __name__ == "__main__":
    unittest.main()
