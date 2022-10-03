@echo off

cls

if not exist bin (
    mkdir bin
)

if "%1" == "-b" (
    odin build . -out:bin/TopDownOdin.exe -debug
) else (
    odin run . -out:bin/TopDownOdin.exe -debug
)

