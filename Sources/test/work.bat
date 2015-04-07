for %%a in (*.csv) do call :addId "%%~Na" "%%a"
goto :EOF

:addId
@echo off
for /f "usebackq delims=" %%b in (%2) do (
  > #.csv echo %~1,%%b
  goto :next
)
:next
for /f "usebackq skip=1 delims=" %%b in (%2) do (
  >> #.csv echo %~1,%%b
)
move #.csv %2