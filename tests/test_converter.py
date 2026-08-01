"""
Pruebas automatizadas para la lógica de conversión (src/converter.py).

Usan los XML de example/ (carpeta personal, no versionada). Si se clona el repo
sin esa carpeta, las pruebas que dependen de ella se omiten automáticamente.
"""
from pathlib import Path

import pytest

from src.converter import FacturaConverter

PROJECT_ROOT = Path(__file__).resolve().parent.parent
EXAMPLE_DIR = PROJECT_ROOT / "example"
FACTURA_XML = EXAMPLE_DIR / "Factura" / "FACTURAE001-34420612069388.XML"
NOTA_CREDITO_XML = EXAMPLE_DIR / "Nota de Credito" / "NOTA_CREDITOE001-14020545837880.XML"
SERIE_F_XML = EXAMPLE_DIR / "Prueba" / "ADMINISTRACION INMOBILIARIA F001-00045318.xml"

BOLETA_XML_CONTENT = """<?xml version='1.0' encoding='UTF-8'?>
<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
         xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">
  <cbc:ID>B001-00000001</cbc:ID>
  <cbc:InvoiceTypeCode>03</cbc:InvoiceTypeCode>
</Invoice>
"""

# Las pruebas de integración requieren los ejemplos personales del autor.
requires_examples = pytest.mark.skipif(
    not FACTURA_XML.exists(), reason="carpeta example/ no disponible"
)


@pytest.fixture(scope="module")
def converter():
    return FacturaConverter()


def make_boleta(path):
    """Crea un XML mínimo de boleta de venta (InvoiceTypeCode 03)."""
    path.write_text(BOLETA_XML_CONTENT, encoding="utf-8")
    return path


class TestInit:
    def test_invalid_engine_raises(self):
        with pytest.raises(ValueError, match="Motor PDF inválido"):
            FacturaConverter(pdf_engine="pdf3000")

    def test_valid_engines_accepted(self):
        for engine in ("auto", "browser", "xhtml2pdf"):
            assert FacturaConverter(pdf_engine=engine).pdf_engine == engine


@requires_examples
class TestDocumentId:
    def test_factura_id(self, converter):
        assert converter.get_document_id(FACTURA_XML) == "E001-344"

    def test_nota_credito_id(self, converter):
        assert converter.get_document_id(NOTA_CREDITO_XML) == "E001-140"

    def test_invalid_xml_raises_not_none(self, converter, tmp_path):
        """Un XML corrupto debe lanzar excepción, nunca devolver None silencioso."""
        bad_xml = tmp_path / "corrupto.xml"
        bad_xml.write_bytes(b"<<<esto no es xml>>>")
        with pytest.raises((ValueError, RuntimeError)):
            converter.get_document_id(bad_xml)


@requires_examples
class TestConvert:
    def test_convert_factura(self, converter, tmp_path):
        pdf_path, engine = converter.convert(FACTURA_XML, tmp_path / "factura.pdf")
        assert Path(pdf_path).exists()
        assert Path(pdf_path).stat().st_size > 0
        assert engine in ("browser", "xhtml2pdf")

    def test_convert_factura_serie_f(self, converter, tmp_path):
        """Las facturas de otras series (F, FF, etc.) también se convierten."""
        pdf_path, engine = converter.convert(SERIE_F_XML, tmp_path / "factura_f.pdf")
        assert Path(pdf_path).exists()
        assert engine in ("browser", "xhtml2pdf")

    def test_convert_nota_credito(self, converter, tmp_path):
        pdf_path, engine = converter.convert(NOTA_CREDITO_XML, tmp_path / "nc.pdf")
        assert Path(pdf_path).exists()
        assert engine in ("browser", "xhtml2pdf")

    def test_convert_with_xhtml2pdf_engine(self, tmp_path):
        """El motor fallback xhtml2pdf también debe generar un PDF válido."""
        converter = FacturaConverter(pdf_engine="xhtml2pdf")
        pdf_path, engine = converter.convert(FACTURA_XML, tmp_path / "fallback.pdf")
        assert Path(pdf_path).exists()
        assert engine == "xhtml2pdf"

    def test_convert_boleta_raises(self, converter, tmp_path):
        """Las boletas de venta NO se convierten: convert() las rechaza."""
        boleta = make_boleta(tmp_path / "boleta.xml")
        with pytest.raises(ValueError, match="Boleta de venta no soportada"):
            converter.convert(boleta, tmp_path / "out.pdf")

    def test_convert_missing_file_raises(self, converter, tmp_path):
        with pytest.raises(FileNotFoundError):
            converter.convert(tmp_path / "no_existe.xml")

    def test_convert_invalid_xml_raises(self, converter, tmp_path):
        bad_xml = tmp_path / "corrupto.xml"
        bad_xml.write_bytes(b"<<<esto no es xml, no se puede recuperar>>>")
        with pytest.raises((ValueError, RuntimeError)):
            converter.convert(bad_xml, tmp_path / "out.pdf")

    def test_unsupported_document_type_raises(self, converter, tmp_path):
        other_xml = tmp_path / "otro.xml"
        other_xml.write_text(
            "<?xml version='1.0' encoding='UTF-8'?><DespatchAdvice></DespatchAdvice>",
            encoding="utf-8",
        )
        with pytest.raises(ValueError, match="no soportado"):
            converter.convert(other_xml, tmp_path / "out.pdf")


@requires_examples
class TestConvertBatch:
    def test_batch_converts_all_invoice_series(self, converter, tmp_path):
        """Serie E y Serie F se convierten; las entradas son dicts consistentes."""
        results = converter.convert_batch([FACTURA_XML, SERIE_F_XML], output_dir=tmp_path)

        assert len(results["converted"]) == 2
        assert results["skipped"] == []
        assert results["errors"] == []

        for converted in results["converted"]:
            # Regresión: las entradas deben ser dicts con claves, no tuplas sueltas.
            assert set(converted) == {"xml", "pdf", "engine"}
            assert Path(converted["pdf"]).exists()

    def test_batch_skips_boletas_with_reason(self, converter, tmp_path):
        """Una boleta colada se omite con motivo claro; la factura se convierte."""
        boleta = make_boleta(tmp_path / "boleta.xml")
        results = converter.convert_batch([boleta, FACTURA_XML], output_dir=tmp_path)

        assert len(results["converted"]) == 1
        assert len(results["skipped"]) == 1
        assert results["errors"] == []

        skipped = results["skipped"][0]
        assert Path(skipped["xml"]).name == "boleta.xml"
        assert "Boleta de venta no soportada" in skipped["reason"]

    def test_batch_reports_errors(self, converter, tmp_path):
        bad_xml = tmp_path / "corrupto.xml"
        bad_xml.write_bytes(b"no es xml")
        results = converter.convert_batch([bad_xml, FACTURA_XML], output_dir=tmp_path)
        assert len(results["errors"]) == 1
        assert len(results["converted"]) == 1
        # Un XML corrupto NUNCA debe clasificarse como omitido.
        assert results["skipped"] == []

    def test_batch_progress_callback(self, converter, tmp_path):
        calls = []
        converter.convert_batch(
            [FACTURA_XML, SERIE_F_XML],
            output_dir=tmp_path,
            progress_callback=lambda i, total, name: calls.append((i, total, name)),
        )
        assert [c[0] for c in calls] == [1, 2]
        assert all(c[1] == 2 for c in calls)
