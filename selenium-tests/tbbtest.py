#!/usr/bin/python
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoSuchElementException
import unittest, time, re
import os

class TBBTest(unittest.TestCase):
    def setUp(self):
        ffbinary = webdriver.firefox.firefox_binary.FirefoxBinary(firefox_path=os.environ['TBB_BIN'])
        ffprofile = webdriver.firefox.firefox_profile.FirefoxProfile(profile_directory=os.environ['TBB_PROFILE'])
        self.driver = webdriver.Firefox(firefox_binary=ffbinary, firefox_profile=ffprofile)
        self.driver.implicitly_wait(30)
        self.base_url = "about:tor"
        self.verificationErrors = []
        self.accept_next_alert = True

    def tearDown(self):
        self.driver.quit()
        self.assertEqual([], self.verificationErrors)

