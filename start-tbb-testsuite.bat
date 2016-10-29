@ECHO OFF
SET TESTSUITEDIR=%~dp0
CD %TESTSUITEDIR%\bundle
CALL bundle-setup.bat
CD ..
bundle\cygwin\bin\bash --login -i -c 'cd $(cygpath -u "$TESTSUITEDIR"); exec /bin/bash'
