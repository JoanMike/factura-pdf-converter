@echo off
setlocal
chcp 65001 >nul
pushd "%~dp0"
echo ==========================================
echo   Factura XML a PDF Converter - Instalador
echo ==========================================
echo.

REM Verificar si Python está instalado
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python no está instalado o no está en el PATH.
    echo Por favor instala Python 3.8 o superior desde https://python.org
    popd
    pause
    exit /b 1
)

echo [OK] Python detectado.
python --version
echo.

REM Crear entorno virtual si no existe
if not exist "venv" (
    echo Creando entorno virtual...
    python -m venv venv
    if errorlevel 1 (
        echo [ERROR] No se pudo crear el entorno virtual.
        popd
        pause
        exit /b 1
    )
    echo [OK] Entorno virtual creado.
) else (
    echo [OK] Entorno virtual ya existe.
)
echo.

REM Activar entorno virtual e instalar dependencias
echo Instalando dependencias...
echo Esto puede tardar unos minutos...
echo.

venv\Scripts\pip install --upgrade pip
venv\Scripts\pip install -r requirements.txt

if errorlevel 1 (
    echo [ERROR] Error al instalar dependencias.
    popd
    pause
    exit /b 1
)

echo.
echo [OK] Dependencias instaladas correctamente.
echo.

echo Instalando motor de navegador (Chromium) para PDF fiel al navegador...
venv\Scripts\python.exe -m playwright install chromium
if errorlevel 1 (
    echo [ADVERTENCIA] No se pudo instalar Chromium de Playwright.
    echo La app seguira funcionando con motor alternativo, pero el formato podria variar.
) else (
    echo [OK] Chromium instalado correctamente.
)
echo.

REM Verificar que existan las plantillas
if not exist "templates\factura2.1.xsl" (
    echo [ADVERTENCIA] No se encontró templates\factura2.1.xsl
    echo Asegúrate de copiar las plantillas a la carpeta templates\
)

if not exist "templates\ebxml21.css" (
    echo [ADVERTENCIA] No se encontró templates\ebxml21.css
    echo Asegúrate de copiar las plantillas a la carpeta templates\
)

echo.
echo ==========================================
echo   Instalación completada exitosamente!
echo ==========================================
echo.
echo Para ejecutar la aplicación:
echo   1. Activa el entorno: venv\Scripts\activate
echo   2. Ejecuta: python run.py
echo.
echo O simplemente haz doble clic en run.bat
echo.
popd
pause
