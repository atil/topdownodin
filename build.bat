@echo off

cls

if "%1" == "-b" (
    odin build . -out:bin/OdinTest.exe -debug
) else (
    odin run . -out:bin/OdinTest.exe -debug
)

