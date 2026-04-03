@echo off
for /F %%i in ('git tag --list --sort=committerdate') do set BUILDTAG=%%i
for /F %%i in ('git rev-parse HEAD') do set BUILDCOMMIT=%%i
set BUILDCOMMIT=%BUILDCOMMIT:~0,8%
for /F %%i in ('git branch --show-current') do set BUILDBRANCH=%%i

echo %BUILDTAG% %BUILDCOMMIT% %BUILDBRANCH%

echo unit Version ;  > ..\src\classes\Version.pas
echo interface >> ..\src\classes\Version.pas
echo type TGitVersion = class >> ..\src\classes\Version.pas
echo const COMMIT = '%BUILDCOMMIT%'; >> ..\src\classes\Version.pas
echo const BRANCH = '%BUILDBRANCH%'; >> ..\src\classes\Version.pas
echo const TAG = '%BUILDTAG%'; >> ..\src\classes\Version.pas
echo end ; >> ..\src\classes\Version.pas
echo implementation >> ..\src\classes\Version.pas
echo end. >> ..\src\classes\Version.pas
