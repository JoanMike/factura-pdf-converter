# AGENTS.md

## Overview

Windows desktop app (CustomTkinter GUI) that converts SUNAT electronic invoices from XML (UBL 2.1) to PDF using XSLT transformation + Chromium rendering. **Invoices of any series (E, F, FF, ...) and credit notes are supported. Boletas de venta (`InvoiceTypeCode = 03`) are NOT converted — they are skipped with a warning.**

## Setup

```batch
install.bat          # Creates venv, installs deps, downloads Chromium
run.bat              # Runs from venv (use this, not python run.py directly)
```

Manual Chromium install if missing:
```batch
venv\Scripts\python -m playwright install chromium
```

Dev setup (tests):
```batch
venv\Scripts\pip install -r requirements-dev.txt
```

Requires Python 3.10+ (developed on 3.14). If Python is upgraded/reinstalled, delete `venv/` and re-run `install.bat` — the venv hardcodes the interpreter path in `venv/pyvenv.cfg`.

## Architecture

```
run.py              # Entrypoint - imports src.main
src/
  main.py           # GUI (FacturaConverterApp) - threading for conversion, logging setup
  converter.py      # Core logic: XML → XSLT → HTML → PDF
templates/
  factura2.1.xsl    # Invoice (Invoice root element)
  nota_credito.xsl  # CreditNote (CreditNote root element)
  ebxml21.css       # Invoice styles
  nota_credito.css  # Credit note styles
tests/              # pytest suite (test_converter.py)
logs/               # Runtime logs (auto-created, gitignored)
example/            # Personal example files (gitignored, never commit)
test_output/        # Scratch output dir (auto-created, gitignored)
```

## Key Behaviors

- **Document type detection**: Uses XML root element (`Invoice` or `CreditNote`) to select template
- **Boleta filter**: Boletas de venta (`Invoice` with `cbc:InvoiceTypeCode = '03'`) are never converted — the XSL template renders them with a wrong title. `_get_skip_reason()` detects them; `convert_batch` reports them as `skipped` (the GUI shows a warning listing them) and direct `convert()` raises `ValueError`. Any other series (E, F, FF, ...) converts normally. Support for boletas may be evaluated later with a real sample XML.
- **Corrupt XML = error, not skip**: `_parse_xml_file` raises `ValueError`/`RuntimeError` for unrecoverable XML; `get_document_id` propagates it. Never swallow these into the "skipped" category.
- **Batch conversion**: `convert_batch` returns `{"converted": [...], "skipped": [...], "errors": [...]}` (dicts, not tuples) and reuses a single Chromium instance for the whole batch. Each XML is parsed once — the parsed tree feeds both validation and `convert(xml_root=...)`.
- **PDF engine**: `auto` (default) tries Chromium first, falls back to xhtml2pdf
- **XML recovery**: Parser attempts auto-recovery for malformed XML before failing
- **Template loading**: Lazy-loaded per document type
- **Logging**: `configure_logging()` in `src/main.py` writes to `logs/factura_converter.log` + console

## Testing

pytest suite:
```batch
venv\Scripts\pip install -r requirements-dev.txt
venv\Scripts\python -m pytest tests/ -v
```

Tests use files from `example/` and skip automatically if that folder is absent (it is gitignored — fresh clones won't have it). Boleta behavior is tested with a synthetic minimal XML fixture (`make_boleta` in test_converter.py).

Manual verification:
```batch
venv\Scripts\python -c "from src.converter import FacturaConverter; c=FacturaConverter(); print(c.convert('example/Factura/FACTURAE001-34420612069388.XML', 'test_output/prueba.pdf'))"
```

## Repository conventions

- **`example/` folders are personal-use and must ALWAYS be in `.gitignore`** (standing rule from the author, applies to every project).
- Also gitignored: `venv/`, `__pycache__/`, `logs/`, `test_output/`.
- Dependencies are pinned in `requirements.txt`; only direct deps are declared (Pillow/pypdf/packaging come in transitively via customtkinter/xhtml2pdf).
- License: MIT (`LICENSE`).

## Gotchas

- Must run from project root (`run.bat` handles this via `pushd`)
- CSS is inlined into HTML before PDF generation (xhtml2pdf requires it)
- xhtml2pdf needs CSS sanitization (missing semicolons, invalid units like `p` → `pt`, `font-weight: none`)
- Template paths are relative to `src/converter.py` parent directory
- XSL templates must use UTF-8 encoding (not ISO-8859-1)
- The venv breaks silently when the base Python is moved/uninstalled (`pyvenv.cfg` points to the old path) — recreate it, don't repair it
