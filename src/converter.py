"""
Módulo para convertir comprobantes XML a PDF usando XSLT y xhtml2pdf.
"""
import logging
import re
from contextlib import contextmanager
from pathlib import Path
from lxml import etree
from xhtml2pdf import pisa

try:
    from playwright.sync_api import Error as PlaywrightError
    from playwright.sync_api import sync_playwright
except Exception:  # pragma: no cover - depende del entorno
    PlaywrightError = Exception
    sync_playwright = None


logger = logging.getLogger(__name__)


class FacturaConverter:
    """Convierte archivos XML de comprobantes SUNAT a PDF.

    Soporta facturas (cualquier serie: E, F, etc.) y notas de crédito.
    Las boletas de venta (Invoice con InvoiceTypeCode '03') NO se convierten:
    la plantilla XSL actual no las representa correctamente.
    """

    CSS_LINK_PATTERN = re.compile(r'<link[^>]+href="[^"]*\.css"[^>]*/?>', re.IGNORECASE)
    INVALID_POINT_UNIT_PATTERN = re.compile(r'(?<![\w.-])(\d+(?:\.\d+)?)p\b')
    INVALID_FONT_WEIGHT_PATTERN = re.compile(r'font-weight\s*:\s*none\s*;', re.IGNORECASE)
    MISSING_SEMICOLON_BEFORE_PROPERTY_PATTERN = re.compile(
        r'(?P<value>:\s*[^;{}]+)\r?\n(?P<indent>\s*)(?P<property>[a-zA-Z-]+\s*:)',
        re.MULTILINE,
    )
    MISSING_SEMICOLON_BEFORE_BRACE_PATTERN = re.compile(r'(:\s*[^;{}]+)(\s*})')
    VALID_PDF_ENGINES = {"auto", "browser", "xhtml2pdf"}
    BROWSER_PDF_MARGIN_MM = {"top": "8mm", "right": "8mm", "bottom": "8mm", "left": "8mm"}
    CBC_NAMESPACE = "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
    BOLETA_TYPE_CODE = "03"  # Catálogo 01 SUNAT: 03 = Boleta de Venta

    def __init__(self, template_dir=None, pdf_engine="auto"):
        """
        Inicializa el convertidor.

        Args:
            template_dir: Directorio donde se encuentran las plantillas XSL y CSS.
                         Si es None, usa el directorio 'templates' relativo al script.
            pdf_engine: Motor para generar PDF: 'auto', 'browser' o 'xhtml2pdf'.
        """
        if template_dir is None:
            self.template_dir = Path(__file__).parent.parent / "templates"
        else:
            self.template_dir = Path(template_dir)

        if pdf_engine not in self.VALID_PDF_ENGINES:
            valid_values = ", ".join(sorted(self.VALID_PDF_ENGINES))
            raise ValueError(f"Motor PDF inválido: {pdf_engine}. Valores válidos: {valid_values}")
        self.pdf_engine = pdf_engine

        # Diccionario para administrar las plantillas según el tipo de documento.
        # IMPORTANTE: Ajusta "nota_credito.xsl" y "nota_credito.css" a los nombres
        # exactos de los archivos que tienes en tu carpeta templates/
        self.templates = {
            "Invoice": {
                "xsl": self.template_dir / "factura2.1.xsl",
                "css": self.template_dir / "ebxml21.css",
                "xslt_transform": None
            },
            "CreditNote": {
                "xsl": self.template_dir / "nota_credito.xsl",
                "css": self.template_dir / "nota_credito.css",
                "xslt_transform": None
            }
        }
        # La carga de las plantillas (XSLT) ahora es dinámica (lazy loading)
        # al momento de procesar cada archivo, según su tipo.

    def _get_template_info(self, root_tag):
        """Devuelve la información de la plantilla según la etiqueta raíz del XML."""
        if root_tag in self.templates:
            return self.templates[root_tag]
        raise ValueError(f"Tipo de documento XML no soportado: {root_tag}")

    def _get_xslt_transform(self, template_info):
        """Carga y compila la transformación XSLT bajo demanda (lazy load)."""
        if template_info["xslt_transform"] is None:
            xsl_path = template_info["xsl"]
            if not xsl_path.exists():
                raise FileNotFoundError(f"No se encontró la plantilla XSLT: {xsl_path}")

            try:
                with open(xsl_path, 'rb') as f:
                    xslt_root = etree.XML(f.read())
                template_info["xslt_transform"] = etree.XSLT(xslt_root)
            except Exception as error:
                raise RuntimeError(f"No se pudo cargar la plantilla XSLT desde: {xsl_path}") from error

        return template_info["xslt_transform"]

    @staticmethod
    def _build_xml_parser(recover=False):
        """Crea un parser XML seguro para evitar dependencias externas y lecturas remotas."""
        return etree.XMLParser(resolve_entities=False, no_network=True, recover=recover)

    @classmethod
    def _sanitize_css_for_xhtml2pdf(cls, css_content):
        """Normaliza reglas CSS incompatibles con xhtml2pdf."""
        # xhtml2pdf es más estricto que el navegador con declaraciones CSS incompletas.
        previous = None
        while previous != css_content:
            previous = css_content
            css_content = cls.MISSING_SEMICOLON_BEFORE_PROPERTY_PATTERN.sub(
                r'\g<value>;\n\g<indent>\g<property>', css_content
            )

        css_content = cls.MISSING_SEMICOLON_BEFORE_BRACE_PATTERN.sub(r'\1;\2', css_content)
        css_content = cls.INVALID_POINT_UNIT_PATTERN.sub(r'\1pt', css_content)
        css_content = cls.INVALID_FONT_WEIGHT_PATTERN.sub('font-weight: normal;', css_content)
        return css_content

    def _fix_css_paths(self, html_content, css_path):
        """
        Incrusta el CSS directamente en el HTML para xhtml2pdf.

        Args:
            html_content: Contenido HTML como string
            css_path: Ruta al archivo CSS a incrustar

        Returns:
            HTML con CSS incrustado
        """
        if not css_path.exists():
            raise FileNotFoundError(f"No se encontró la plantilla CSS: {css_path}")

        # Leer el contenido del CSS
        with open(css_path, 'r', encoding='utf-8') as f:
            css_content = f.read()

        css_content = self._sanitize_css_for_xhtml2pdf(css_content)

        # Reemplazar el link externo con el CSS incrustado
        style_tag = f'<style type="text/css">\n{css_content}\n</style>'

        html_fixed = self.CSS_LINK_PATTERN.sub(style_tag, html_content)
        return html_fixed

    def _get_skip_reason(self, xml_root):
        """Devuelve el motivo por el que el documento no debe convertirse, o None.

        Las boletas de venta (Invoice con InvoiceTypeCode '03') no se soportan:
        la plantilla XSL actual no las representa correctamente.
        """
        root_tag = etree.QName(xml_root.tag).localname
        if root_tag == "Invoice":
            type_code = xml_root.findtext(f"{{{self.CBC_NAMESPACE}}}InvoiceTypeCode")
            if type_code == self.BOLETA_TYPE_CODE:
                return "Boleta de venta no soportada (solo facturas y notas de crédito)"
        return None

    def _transform_xml_to_html(self, xml_path, xml_root=None):
        """Transforma el XML a HTML aplicando XSLT y saneamiento de CSS."""
        if xml_root is None:
            xml_root = self._parse_xml_file(xml_path)

        skip_reason = self._get_skip_reason(xml_root)
        if skip_reason:
            raise ValueError(f"{skip_reason}: {xml_path}")

        # Detectar el tipo de documento ignorando el namespace (ej: 'Invoice', 'CreditNote')
        root_tag = etree.QName(xml_root.tag).localname

        template_info = self._get_template_info(root_tag)
        xslt_transform = self._get_xslt_transform(template_info)

        try:
            result_tree = xslt_transform(xml_root)
        except Exception as error:
            raise RuntimeError(f"No se pudo transformar el XML ({root_tag}) con la plantilla XSLT: {xml_path}") from error

        html_content = str(result_tree)
        return self._fix_css_paths(html_content, template_info["css"])

    @staticmethod
    def _convert_with_xhtml2pdf(html_content, output_path):
        """Genera PDF usando xhtml2pdf (fallback compatible)."""
        with open(output_path, 'wb') as pdf_file:
            pisa_status = pisa.CreatePDF(
                html_content,
                dest=pdf_file,
                encoding='utf-8'
            )

        if pisa_status.err:
            raise RuntimeError(f"Error al generar PDF para '{Path(output_path).name}' con xhtml2pdf.")

    @classmethod
    def _render_pdf_with_browser(cls, browser, html_content, output_path):
        """Renderiza el HTML a PDF usando una instancia de Chromium ya abierta."""
        page = browser.new_page()
        try:
            page.set_content(html_content, wait_until='load')
            page.emulate_media(media='screen')
            page.pdf(
                path=str(output_path),
                format='A4',
                margin=cls.BROWSER_PDF_MARGIN_MM,
                print_background=True,
                prefer_css_page_size=True,
            )
        finally:
            page.close()

    @classmethod
    def _convert_with_browser(cls, html_content, output_path, browser=None):
        """Genera PDF usando Chromium (Playwright) para replicar mejor el navegador.

        Si se recibe una instancia de `browser`, la reutiliza (conversiones en lote);
        si no, lanza una instancia temporal de Chromium.
        """
        if sync_playwright is None:
            raise RuntimeError(
                "Playwright no está instalado. Ejecuta: "
                "venv\\Scripts\\pip install playwright y luego "
                "venv\\Scripts\\python -m playwright install chromium"
            )

        try:
            if browser is not None:
                cls._render_pdf_with_browser(browser, html_content, output_path)
            else:
                with sync_playwright() as playwright:
                    with playwright.chromium.launch(headless=True) as single_browser:
                        cls._render_pdf_with_browser(single_browser, html_content, output_path)
        except PlaywrightError as error:
            raise RuntimeError(f"Error al generar PDF con motor de navegador: {error}") from error

    @contextmanager
    def _browser_session(self):
        """Abre una instancia de Chromium reutilizable para conversiones en lote.

        Devuelve None si Playwright no está disponible (cada convert() aplicará
        entonces su propio fallback).
        """
        if sync_playwright is None:
            yield None
            return
        with sync_playwright() as playwright:
            with playwright.chromium.launch(headless=True) as browser:
                yield browser

    def _parse_xml_file(self, xml_path):
        """Parsea el XML de entrada con validación y mensajes de error claros."""
        try:
            with open(xml_path, 'rb') as xml_file:
                xml_content = xml_file.read()
        except Exception as error:
            raise RuntimeError(f"No se pudo leer el XML de entrada: {xml_path}") from error

        strict_parser = self._build_xml_parser(recover=False)
        try:
            return etree.fromstring(xml_content, strict_parser)
        except etree.XMLSyntaxError:
            logger.warning(
                "El XML '%s' tiene errores de sintaxis. Se intentará recuperación automática.",
                xml_path,
            )

            recover_parser = self._build_xml_parser(recover=True)
            try:
                recovered_root = etree.fromstring(xml_content, recover_parser)
                if recovered_root is None:
                    raise ValueError("No se pudo recuperar el contenido XML.")
                return recovered_root
            except Exception as recover_error:
                raise ValueError(
                    f"El XML es inválido o está mal formado y no se pudo recuperar: {xml_path}"
                ) from recover_error
        except Exception as error:
            raise RuntimeError(f"No se pudo procesar el XML de entrada: {xml_path}") from error

    @staticmethod
    def _get_document_id_from_root(xml_root):
        """Extrae el ID (Serie-Correlativo) de un árbol XML ya parseado."""
        # El ID del documento es un hijo directo de la raíz (Invoice/CreditNote)
        for child in xml_root:
            if etree.QName(child).localname == 'ID':
                return child.text.strip() if child.text else None
        return None

    def get_document_id(self, xml_path):
        """
        Extrae el ID del documento (Serie-Correlativo) del XML.
        Busca el ID que es hijo directo de la raíz (estándar UBL).

        Args:
            xml_path: Ruta al archivo XML

        Returns:
            String con el ID del documento (ej. 'E001-1' o 'F001-1') o None si no se encuentra.

        Raises:
            RuntimeError: Si el archivo no se puede leer o procesar.
            ValueError: Si el XML es inválido y no se pudo recuperar.
        """
        xml_root = self._parse_xml_file(xml_path)
        return self._get_document_id_from_root(xml_root)

    def convert(self, xml_path, output_path=None, xml_root=None, browser=None):
        """
        Convierte un archivo XML a PDF.

        Args:
            xml_path: Ruta al archivo XML del comprobante
            output_path: Ruta donde guardar el PDF. Si es None, usa el mismo
                        nombre que el XML pero con extensión .pdf
            xml_root: Árbol XML ya parseado (opcional, evita releer el archivo)
            browser: Instancia de Chromium reutilizable (opcional, uso en lotes)

        Returns:
            Tupla (ruta_pdf, motor_usado) donde motor_usado es 'browser' o 'xhtml2pdf'

        Raises:
            ValueError: Si el documento es una boleta de venta (no soportada)
                       o un tipo de documento sin plantilla.
        """
        xml_path = Path(xml_path)

        if not xml_path.exists():
            raise FileNotFoundError(f"No se encontró el archivo XML: {xml_path}")

        # Determinar ruta de salida
        if output_path is None:
            output_path = xml_path.with_suffix('.pdf')
        else:
            output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)

        html_content = self._transform_xml_to_html(xml_path, xml_root=xml_root)
        engine_used = None

        if self.pdf_engine == "browser":
            self._convert_with_browser(html_content, output_path, browser=browser)
            engine_used = "browser"
            logger.info("PDF generado con motor browser: %s", output_path)
        elif self.pdf_engine == "xhtml2pdf":
            self._convert_with_xhtml2pdf(html_content, output_path)
            engine_used = "xhtml2pdf"
            logger.info("PDF generado con motor xhtml2pdf: %s", output_path)
        else:
            try:
                self._convert_with_browser(html_content, output_path, browser=browser)
                engine_used = "browser"
                logger.info("PDF generado con motor browser: %s", output_path)
            except Exception as browser_error:
                logger.warning(
                    "Fallo motor browser (%s). Se usará xhtml2pdf como fallback.",
                    browser_error,
                )
                self._convert_with_xhtml2pdf(html_content, output_path)
                engine_used = "xhtml2pdf"
                logger.info("PDF generado con motor xhtml2pdf (fallback): %s", output_path)

        logger.info("PDF generado correctamente: %s", output_path)

        return str(output_path.resolve()), engine_used

    def convert_batch(self, xml_paths, output_dir=None, progress_callback=None):
        """
        Convierte múltiples archivos XML a PDF reutilizando una sola instancia
        de Chromium para todo el lote.

        Convierte facturas de cualquier serie (E, F, etc.) y notas de crédito.
        Las boletas de venta NO se convierten: se reportan en "skipped".

        Args:
            xml_paths: Lista de rutas a archivos XML
            output_dir: Directorio donde guardar los PDFs. Si es None, se guardan
                       en la misma ubicación que cada XML.
            progress_callback: Función callback(current, total, current_file) para reportar progreso

        Returns:
            Diccionario con tres listas:
              - "converted": [{"xml": ruta, "pdf": ruta_pdf, "engine": motor}]
              - "skipped":   [{"xml": ruta, "reason": motivo}]  (boletas detectadas)
              - "errors":    [{"xml": ruta, "error": mensaje}]
        """
        results = {"converted": [], "skipped": [], "errors": []}
        total = len(xml_paths)

        with self._browser_session() as browser:
            for i, xml_path in enumerate(xml_paths, 1):
                xml_path = Path(xml_path)
                status = xml_path.name
                try:
                    # Parsear una sola vez: el árbol se reutiliza para la
                    # validación del documento y para la conversión.
                    xml_root = self._parse_xml_file(xml_path)

                    skip_reason = self._get_skip_reason(xml_root)
                    if skip_reason:
                        logger.info("Documento omitido (%s): %s", skip_reason, xml_path)
                        results["skipped"].append({"xml": str(xml_path), "reason": skip_reason})
                        status = f"Omitido (boleta no soportada): {xml_path.name}"
                        continue

                    if output_dir:
                        output_path = Path(output_dir) / xml_path.with_suffix('.pdf').name
                    else:
                        output_path = None

                    pdf_path, engine = self.convert(
                        xml_path, output_path, xml_root=xml_root, browser=browser
                    )
                    results["converted"].append({
                        "xml": str(xml_path),
                        "pdf": pdf_path,
                        "engine": engine,
                    })
                    status = f"Completado: {xml_path.name}"

                except Exception as e:
                    logger.error("Error al convertir '%s': %s", xml_path, e)
                    results["errors"].append({"xml": str(xml_path), "error": str(e)})
                    status = f"ERROR: {xml_path.name}"

                finally:
                    if progress_callback:
                        progress_callback(i, total, status)

        return results
