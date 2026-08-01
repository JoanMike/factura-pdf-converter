@echo off
setlocal
chcp 65001 >nul
pushd "%~dp0"

REM Verificar entorno virtual
if not exist "venv\Scripts\python.exe" (
    echo [ERROR] No se encontró el entorno virtual.
    echo Ejecuta primero: install.bat
    popd
    pause
    exit /b 1
)

REM Ejecutar aplicación
venv\Scripts\python.exe run.py

if errorlevel 1 (
    echo.
    echo [ERROR] La aplicación se cerró con errores.
    pause
)

popd
