@echo off

ren %SystemRoot%\System32\dism.exe dism2.exe
copy /y %~dp0dism_%Processor_Architecture%.exe %SystemRoot%\System32\dism.exe
