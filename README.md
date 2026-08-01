# Factura XML a PDF Converter

Aplicación de escritorio moderna para convertir facturas electrónicas SUNAT de formato XML a PDF.

## Características

- ✅ Interfaz gráfica moderna y intuitiva con CustomTkinter
- ✅ Conversión de archivos XML individuales o en lote
- ✅ Soporte para facturas y notas de crédito SUNAT UBL 2.1 de **todas las series** (E, F, FF, etc.)
- ⚠️ Detección de boletas de venta: se omiten con advertencia (no soportadas por ahora)
- ✅ Selección de directorio de salida personalizado
- ✅ Barra de progreso en tiempo real
- ✅ Manejo de errores amigable
- ✅ Compatible con Windows 10/11
- ✅ Renderizado PDF con Chromium (resultado más fiel al navegador)
- ✅ Recuperación automática para XML con errores leves de sintaxis
- ✅ Sección "Información de la detracción" generada desde el XML
- ✅ Catálogo 54 SUNAT de detracción mapeado (códigos vigentes)
- ✅ Registro de actividad en `logs/factura_converter.log` para diagnóstico

## Requisitos

- Windows 10/11
- Python 3.10 o superior (probado con Python 3.14)

## Instalación Rápida

### Opción 1: Script de instalación automática (Recomendado)

1. Abre una terminal (cmd) en la carpeta del proyecto
2. Ejecuta el instalador:
   ```batch
   install.bat
   ```
3. Espera a que se complete la instalación
4. Ejecuta la aplicación:
   ```batch
   run.bat
   ```

### Opción 2: Instalación manual

1. Crea un entorno virtual:
   ```bash
   python -m venv venv
   ```

2. Activa el entorno virtual:
   ```bash
   venv\Scripts\activate
   ```

3. Instala las dependencias:
   ```bash
   pip install -r requirements.txt
   ```

4. Instala Chromium para el motor de PDF:
   ```bash
   python -m playwright install chromium
   ```

5. Ejecuta la aplicación:
   ```bash
   python run.py
   ```

## Uso

### Ejecutar la aplicación

Después de la instalación, simplemente haz doble clic en **`run.bat`** o ejecuta:

```bash
run.bat
```

También puedes ejecutar directamente con Python desde la raíz del proyecto:

```bash
venv\Scripts\python run.py
```

### Instrucciones de uso

1. **Seleccionar archivos XML**:
   - Haz clic en "📁 Seleccionar un archivo" para convertir un solo archivo
   - Haz clic en "📂 Seleccionar varios archivos" para convertir múltiples archivos

2. **Elegir directorio de salida** (opcional):
   - Por defecto, los PDFs se guardan en la misma ubicación que los XML
   - Haz clic en "Cambiar" para seleccionar otro directorio

3. **Convertir**:
   - Haz clic en "🚀 Convertir a PDF"
   - Espera a que se complete la conversión
   - Los archivos PDF se generarán automáticamente

> **Nota:** Se convierten facturas de cualquier serie (E, F, FF, etc.) y notas de crédito.
> Si entre los archivos se cuela una **boleta de venta**, NO se convierte: se omite y se
> muestra una advertencia al final del proceso con el nombre del archivo. Si un XML está
> dañado o no se puede leer, se reporta como **error** (no como omitido) y queda registrado
> en el log.

### Prueba rápida en consola (sin interfaz)

Para validar que el motor de conversión está funcionando:

```bash
venv\Scripts\python -c "from src.converter import FacturaConverter; c=FacturaConverter(); print(c.convert('example/Factura/FACTURAE001-34420612069388.XML', 'test_output/prueba_manual.pdf'))"
```

## Pruebas automatizadas

El proyecto incluye pruebas con `pytest` sobre la lógica de conversión:

```bash
venv\Scripts\pip install -r requirements-dev.txt
venv\Scripts\python -m pytest tests/ -v
```

## Novedades Recientes

- Se eliminó la restricción de Serie E: ahora se convierten facturas de cualquier serie y notas de crédito.
- Las boletas de venta (`InvoiceTypeCode = 03`) se detectan y se omiten con advertencia (su soporte se evaluará más adelante).
- Un XML corrupto ahora se reporta como error, nunca como "omitido".
- Las conversiones en lote reutilizan una sola instancia de Chromium (más rápidas).
- Los errores de conversión quedan registrados en `logs/factura_converter.log`.
- Se mejoró la compatibilidad entre series y proveedores con variaciones de estructura XML.
- Se corrigió el cálculo de "Sub total Ventas" para evitar valores `NaN` cuando faltan nodos opcionales.
- Se corrigió el cálculo de "Monto neto pendiente de pago" para escenarios con detracción + crédito.
- Se añadió la sección final "Información de la detracción" con:
   - leyenda,
   - código y descripción del bien/servicio,
   - medio de pago,
   - cuenta bancaria,
   - porcentaje,
   - monto de detracción.
- Se implementó el mapeo del Catálogo 54 (tipos de bienes y servicios sujetos al SPOT) en la plantilla XSL.
- Se añadió modo de recuperación para XML mal formado leve, evitando fallas en casos recuperables.

## Estructura del proyecto

```
factura_pdf_converter/
├── venv/                   # Entorno virtual Python (no versionado)
├── src/
│   ├── __init__.py
│   ├── converter.py        # Lógica de conversión XML → PDF
│   └── main.py             # Interfaz gráfica
├── templates/
│   ├── factura2.1.xsl      # Plantilla XSLT para facturas
│   ├── ebxml21.css         # Estilos CSS para facturas
│   ├── nota_credito.xsl    # Plantilla XSLT para notas de crédito
│   └── nota_credito.css    # Estilos CSS para notas de crédito
├── tests/                  # Pruebas automatizadas (pytest)
├── logs/                   # Logs de la aplicación (se genera en ejecución, no versionado)
├── example/                # Ejemplos de uso personal (no versionado)
├── test_output/            # Salidas de prueba (no versionado)
├── run.py                  # Script de inicio
├── run.bat                 # Script de inicio Windows
├── install.bat             # Script de instalación Windows
├── requirements.txt        # Dependencias Python
├── requirements-dev.txt    # Dependencias de desarrollo (tests)
├── .gitignore
├── LICENSE                 # Licencia MIT
└── README.md               # Este archivo
```

## Dependencias principales

- **customtkinter**: Interfaz gráfica moderna
- **lxml**: Procesamiento XML y XSLT
- **xhtml2pdf**: Generación de PDF desde HTML (motor alternativo)
- **playwright**: Impresión a PDF usando Chromium (más fiel al navegador)

> Pillow, pypdf y packaging se instalan automáticamente como dependencias transitivas de
> customtkinter y xhtml2pdf; no es necesario declararlas.

## Solución de problemas

### Error "No se encontró la plantilla XSL"

Asegúrate de que los archivos `factura2.1.xsl`, `nota_credito.xsl` y sus CSS estén en la carpeta `templates/`.

### Error al convertir

Verifica que el archivo XML sea una factura SUNAT válida en formato UBL 2.1.

Si el XML tiene errores de sintaxis leves, el sistema intentará recuperarlo automáticamente.
Si el archivo está muy dañado o incompleto, la conversión sí puede fallar y el archivo se
reportará como error (con detalle en `logs/factura_converter.log`).

### Código de detracción sin descripción

El aplicativo incluye mapeo del Catálogo 54 vigente. Si en algún XML aparece un código nuevo/no contemplado por SUNAT en la plantilla actual, se mostrará como no mapeado y será necesario actualizar la plantilla.

### Diferencias de formato entre navegador y PDF

La aplicación usa por defecto un motor de navegador (Chromium) para generar el PDF y acercarse al resultado visual del navegador.

Si falta Chromium, instala/reinstala:
```bash
venv\Scripts\python -m playwright install chromium
```

### La aplicación no inicia

1. Verifica que el entorno virtual esté creado correctamente
2. Si el entorno quedó creado con otra versión de Python (ej. desinstalaste o actualizaste Python),
   bórralo y recréalo:
   ```bash
   rmdir /s /q venv
   install.bat
   ```
3. Reinstala las dependencias:
   ```bash
   venv\Scripts\pip install -r requirements.txt
   ```

### Error "No module named 'src'"

Asegúrate de ejecutar la aplicación desde la carpeta del proyecto (`factura_pdf_converter`):
```bash
cd ruta\a\factura_pdf_converter
python run.py
```

Alternativamente, usa `run.bat`, que ya fija la carpeta correcta automáticamente.

## Notas

- La aplicación utiliza las plantillas XSL y CSS proporcionadas por SUNAT para mantener el formato oficial de las facturas.
- Compatible con facturas y notas de crédito electrónicas de cualquier serie. Las boletas de venta no se convierten (se omiten con advertencia).
- El motor por defecto es `auto`: intenta primero `browser` (Chromium) y usa `xhtml2pdf` como fallback si Chromium no está disponible.
- La carpeta `example/` es de uso personal y está excluida del control de versiones (`.gitignore`).

## Licencia

Distribuido bajo licencia MIT. Ver archivo [LICENSE](LICENSE).

## Autor

Desarrollado por Jose Miguel Maldonado Garcia para facilitar la gestión de facturas electrónicas SUNAT.
