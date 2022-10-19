@echo off

cls

if not exist bin\ (
    mkdir bin
)

if "%1" == "-b" (
    odin build . -out:bin/TopDownOdin.exe -debug -o:minimal
) else if "%1" == "-t" (
    odin test .
) else (
    odin run . -out:bin/TopDownOdin.exe -debug -o:minimal

)

