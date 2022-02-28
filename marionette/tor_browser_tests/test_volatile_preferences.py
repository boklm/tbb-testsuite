import os.path

from marionette_harness import MarionetteTestCase
import testsuite

class Test(MarionetteTestCase):

    def test_volatile_preferences(self):
        with self.marionette.using_context('chrome'):
            profile_path = self.marionette.execute_script('''
return Services.dirsvc.get("ProfD", Components.interfaces.nsIFile).path;
''')
            # This file does not exist by default in Tor Browser
            perm_file = profile_path + '/permissions.sqlite'
            self.assertFalse(os.path.exists(perm_file))
            script = '''
const SITE = "https://www.torproject.org";
const KEY = "storageAccessAPI";
const principal = Services.scriptSecurityManager.createContentPrincipalFromOrigin(SITE);
SitePermissions.setForPrincipal(principal, KEY, SitePermissions.ALLOW);
return SitePermissions.getForPrincipal(principal, KEY).state == SitePermissions.ALLOW;
'''
            script_succeeded = self.marionette.execute_script(script)
            self.assertTrue(script_succeeded)
            self.assertFalse(os.path.exists(perm_file))
