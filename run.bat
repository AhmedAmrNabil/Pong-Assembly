
set PWD=%CD%
set PROG="pong"
powershell -Command "(gc dosbox-x.conf) -replace '--path--', '%CD%' -replace '--prog--', '%PROG%' | Out-File -encoding ASCII dosbox-x-generated.conf"

del *.exe
del *.obj
del *.map

start "" "C:\DOSBox-X\dosbox-x.exe" -conf dosbox-x-generated.conf