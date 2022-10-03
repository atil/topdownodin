@echo off

cls

if "%1" == "-b" (
    odin build . -out:bin/TopDown.exe -debug
) else (
    odin run . -out:bin/TopDown.exe -debug
)

