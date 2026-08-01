"""
Interfaz gráfica moderna para el conversor de comprobantes XML a PDF.
Usa CustomTkinter para un diseño moderno y atractivo.
"""
import logging
import threading
from pathlib import Path
from tkinter import filedialog, messagebox
import customtkinter as ctk

try:
    from .converter import FacturaConverter
except ImportError:
    from converter import FacturaConverter


logger = logging.getLogger(__name__)

PROJECT_ROOT = Path(__file__).resolve().parent.parent
LOG_FILE = PROJECT_ROOT / "logs" / "factura_converter.log"


def configure_logging():
    """Configura logging a archivo (y consola) para diagnóstico en producción."""
    if logging.getLogger().handlers:
        return  # Ya configurado (ej. en pruebas)
    LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
        handlers=[
            logging.FileHandler(LOG_FILE, encoding="utf-8"),
            logging.StreamHandler(),
        ],
    )


class FacturaConverterApp(ctk.CTk):
    """Aplicación principal del conversor de comprobantes."""

    UI_SCALE_FACTOR = 0.8
    BASE_WINDOW_WIDTH = 800
    BASE_WINDOW_HEIGHT = 850
    BASE_MIN_WIDTH = 800
    BASE_MIN_HEIGHT = 600

    def __init__(self):
        super().__init__()

        ctk.set_widget_scaling(self.UI_SCALE_FACTOR)

        window_width = int(self.BASE_WINDOW_WIDTH * self.UI_SCALE_FACTOR)
        window_height = int(self.BASE_WINDOW_HEIGHT * self.UI_SCALE_FACTOR)
        min_width = int(self.BASE_MIN_WIDTH * self.UI_SCALE_FACTOR)
        min_height = int(self.BASE_MIN_HEIGHT * self.UI_SCALE_FACTOR)

        # Configuración de la ventana
        self.title("Conversor de Comprobantes XML a PDF | Jose Miguel Maldonado Garcia")
        self.geometry(f"{window_width}x{window_height}")
        self.minsize(min_width, min_height)

        # Configurar tema
        ctk.set_appearance_mode("System")  # System, Dark, Light
        ctk.set_default_color_theme("blue")  # blue, green, dark-blue

        # Inicializar el convertidor
        try:
            self.converter = FacturaConverter()
        except Exception as e:
            messagebox.showerror("Error", f"Error al inicializar el convertidor:\n{str(e)}")
            self.destroy()
            raise

        # Variables
        self.selected_files = []
        self.output_dir = None
        self.is_processing = False

        # Crear interfaz
        self._create_ui()

    def _create_ui(self):
        """Crea la interfaz de usuario."""
        # Frame principal
        self.grid_columnconfigure(0, weight=1)
        self.grid_rowconfigure(0, weight=1)

        # Contenedor principal
        main_frame = ctk.CTkFrame(self, fg_color="transparent")
        main_frame.grid(row=0, column=0, padx=20, pady=20, sticky="nsew")
        main_frame.grid_columnconfigure(0, weight=1)
        main_frame.grid_rowconfigure(1, weight=1)

        # ===== HEADER =====
        header_frame = ctk.CTkFrame(main_frame, fg_color="transparent")
        header_frame.grid(row=0, column=0, padx=0, pady=(0, 20), sticky="ew")

        # Título
        title_label = ctk.CTkLabel(
            header_frame,
            text="📄 Conversor de Comprobantes XML a PDF",
            font=ctk.CTkFont(size=28, weight="bold")
        )
        title_label.pack(pady=(0, 5))

        # Subtítulo
        subtitle_label = ctk.CTkLabel(
            header_frame,
            text="Convierte facturas y notas de crédito SUNAT de XML a PDF fácilmente",
            font=ctk.CTkFont(size=14),
            text_color=("gray35", "gray65")
        )
        subtitle_label.pack()

        # ===== CONTENT =====
        content_frame = ctk.CTkFrame(main_frame)
        content_frame.grid(row=1, column=0, padx=0, pady=0, sticky="nsew")
        content_frame.grid_columnconfigure(0, weight=1)
        content_frame.grid_rowconfigure(2, weight=1)

        # --- Sección de selección de archivos ---
        file_section = ctk.CTkFrame(content_frame, fg_color="transparent")
        file_section.grid(row=0, column=0, padx=20, pady=(20, 10), sticky="ew")
        file_section.grid_columnconfigure(0, weight=1)

        file_label = ctk.CTkLabel(
            file_section,
            text="Archivos XML a convertir:",
            font=ctk.CTkFont(size=16, weight="bold")
        )
        file_label.grid(row=0, column=0, padx=0, pady=(0, 10), sticky="w")

        # Botones de selección
        btn_frame = ctk.CTkFrame(file_section, fg_color="transparent")
        btn_frame.grid(row=1, column=0, padx=0, pady=0, sticky="ew")
        btn_frame.grid_columnconfigure((0, 1, 2), weight=1)

        self.single_file_btn = ctk.CTkButton(
            btn_frame,
            text="📁 Seleccionar un archivo",
            font=ctk.CTkFont(size=15),
            height=40,
            command=self._select_single_file
        )
        self.single_file_btn.grid(row=0, column=0, padx=(0, 5), sticky="ew")

        self.multiple_files_btn = ctk.CTkButton(
            btn_frame,
            text="📂 Seleccionar varios archivos",
            font=ctk.CTkFont(size=15),
            height=40,
            command=self._select_multiple_files
        )
        self.multiple_files_btn.grid(row=0, column=1, padx=5, sticky="ew")

        self.clear_files_btn = ctk.CTkButton(
            btn_frame,
            text="🗑️ Limpiar",
            font=ctk.CTkFont(size=15),
            height=40,
            fg_color="#6c757d",
            hover_color="#5a6268",
            command=self._clear_files
        )
        self.clear_files_btn.grid(row=0, column=2, padx=(5, 0), sticky="ew")

        # --- Lista de archivos seleccionados ---
        list_frame = ctk.CTkFrame(content_frame)
        list_frame.grid(row=1, column=0, padx=20, pady=10, sticky="ew")
        list_frame.grid_columnconfigure(0, weight=1)

        list_header = ctk.CTkLabel(
            list_frame,
            text="Archivos seleccionados:",
            font=ctk.CTkFont(size=14, weight="bold")
        )
        list_header.grid(row=0, column=0, padx=15, pady=(10, 5), sticky="w")

        # Scrollable frame para la lista
        self.files_scroll = ctk.CTkScrollableFrame(list_frame, height=150)
        self.files_scroll.grid(row=1, column=0, padx=15, pady=(0, 15), sticky="ew")
        self.files_scroll.grid_columnconfigure(0, weight=1)

        self.files_label = ctk.CTkLabel(
            self.files_scroll,
            text="No hay archivos seleccionados",
            font=ctk.CTkFont(size=14),
            text_color=("gray35", "gray65")
        )
        self.files_label.grid(row=0, column=0, padx=0, pady=20)

        # --- Opciones de salida ---
        options_frame = ctk.CTkFrame(content_frame, fg_color="transparent")
        options_frame.grid(row=2, column=0, padx=20, pady=10, sticky="nsew")
        options_frame.grid_columnconfigure(0, weight=1)

        # Directorio de salida
        output_label = ctk.CTkLabel(
            options_frame,
            text="Directorio de salida:",
            font=ctk.CTkFont(size=16, weight="bold")
        )
        output_label.grid(row=0, column=0, padx=0, pady=(0, 10), sticky="w")

        output_btn_frame = ctk.CTkFrame(options_frame, fg_color="transparent")
        output_btn_frame.grid(row=1, column=0, padx=0, pady=0, sticky="ew")
        output_btn_frame.grid_columnconfigure(0, weight=1)

        self.output_path_label = ctk.CTkLabel(
            output_btn_frame,
            text="Misma ubicación que los archivos XML",
            font=ctk.CTkFont(size=14),
            fg_color=("gray90", "gray20"),
            corner_radius=6,
            height=35
        )
        self.output_path_label.grid(row=0, column=0, padx=(0, 10), sticky="ew")

        self.output_btn = ctk.CTkButton(
            output_btn_frame,
            text="Cambiar",
            width=100,
            command=self._select_output_dir
        )
        self.output_btn.grid(row=0, column=1, padx=0)

        # --- Barra de progreso ---
        progress_frame = ctk.CTkFrame(content_frame, fg_color="transparent")
        progress_frame.grid(row=3, column=0, padx=20, pady=(20, 10), sticky="ew")
        progress_frame.grid_columnconfigure(0, weight=1)

        self.progress_bar = ctk.CTkProgressBar(progress_frame, height=20)
        self.progress_bar.grid(row=0, column=0, padx=0, pady=(0, 10), sticky="ew")
        self.progress_bar.set(0)

        self.progress_label = ctk.CTkLabel(
            progress_frame,
            text="Listo para convertir",
            font=ctk.CTkFont(size=14)
        )
        self.progress_label.grid(row=1, column=0, padx=0, pady=0)

        # --- Botón de conversión ---
        self.convert_btn = ctk.CTkButton(
            content_frame,
            text="🚀 Convertir a PDF",
            font=ctk.CTkFont(size=18, weight="bold"),
            height=50,
            fg_color="#07632d",
            hover_color="#064620",
            command=self._start_conversion
        )
        self.convert_btn.grid(row=4, column=0, padx=20, pady=(10, 20), sticky="ew")

        # --- Footer ---
        footer_frame = ctk.CTkFrame(main_frame, fg_color="transparent")
        footer_frame.grid(row=2, column=0, padx=0, pady=(10, 0), sticky="ew")

        footer_label = ctk.CTkLabel(
            footer_frame,
            text="Compatible con comprobantes electrónicos SUNAT UBL 2.1",
            font=ctk.CTkFont(size=13),
            text_color=("gray35", "gray65")
        )
        footer_label.pack()

    def _select_single_file(self):
        """Abre diálogo para seleccionar un archivo XML."""
        file_path = filedialog.askopenfilename(
            title="Seleccionar archivo XML (Factura o Nota de Crédito)",
            filetypes=[("Archivos XML", "*.xml"), ("Todos los archivos", "*.*")]
        )

        if file_path:
            self.selected_files = [file_path]
            self._update_files_list()

    def _select_multiple_files(self):
        """Abre diálogo para seleccionar múltiples archivos XML."""
        file_paths = filedialog.askopenfilenames(
            title="Seleccionar archivos XML (Facturas o Notas de Crédito)",
            filetypes=[("Archivos XML", "*.xml"), ("Todos los archivos", "*.*")]
        )

        if file_paths:
            self.selected_files = list(file_paths)
            self._update_files_list()

    def _clear_files(self):
        """Limpia la lista de archivos seleccionados."""
        self.selected_files = []
        self._update_files_list()
        self.progress_bar.set(0)
        self.progress_label.configure(text="Listo para convertir")

    def _update_files_list(self):
        """Actualiza la visualización de archivos seleccionados."""
        # Limpiar lista actual
        for widget in self.files_scroll.winfo_children():
            widget.destroy()

        if not self.selected_files:
            self.files_label = ctk.CTkLabel(
                self.files_scroll,
                text="No hay archivos seleccionados",
                font=ctk.CTkFont(size=14),
                text_color=("gray35", "gray65")
            )
            self.files_label.grid(row=0, column=0, padx=0, pady=20)
            return

        # Mostrar archivos
        for i, file_path in enumerate(self.selected_files):
            file_name = Path(file_path).name
            file_label = ctk.CTkLabel(
                self.files_scroll,
                text=f"{i+1}. {file_name}",
                font=ctk.CTkFont(size=11),
                anchor="w"
            )
            file_label.grid(row=i, column=0, padx=5, pady=2, sticky="w")

    def _select_output_dir(self):
        """Abre diálogo para seleccionar directorio de salida."""
        dir_path = filedialog.askdirectory(title="Seleccionar directorio de salida")

        if dir_path:
            self.output_dir = dir_path
            # Truncar si es muy largo
            display_path = dir_path
            if len(display_path) > 50:
                display_path = "..." + display_path[-47:]
            self.output_path_label.configure(text=display_path)

    def _start_conversion(self):
        """Inicia el proceso de conversión."""
        if not self.selected_files:
            messagebox.showwarning("Sin archivos", "Por favor selecciona al menos un archivo XML.")
            return

        if self.is_processing:
            return

        self.is_processing = True
        self.progress_bar.set(0)
        self.progress_label.configure(text="Iniciando conversión...")
        self.convert_btn.configure(state="disabled", text="⏳ Procesando...")
        self.single_file_btn.configure(state="disabled")
        self.multiple_files_btn.configure(state="disabled")
        self.clear_files_btn.configure(state="disabled")
        self.output_btn.configure(state="disabled")

        # Ejecutar conversión en un hilo separado
        thread = threading.Thread(target=self._convert_files, daemon=True)
        thread.start()

    def _convert_files(self):
        """Ejecuta la conversión de archivos en lote (hilo trabajador)."""

        def on_progress(current, total, message):
            self.after(0, lambda: self._update_progress(current, total, message))

        try:
            results = self.converter.convert_batch(
                self.selected_files,
                output_dir=self.output_dir,
                progress_callback=on_progress,
            )
        except Exception as unexpected_error:
            logger.exception("Error inesperado en el proceso de conversión")
            results = {
                "converted": [],
                "skipped": [],
                "errors": [{"xml": "", "error": f"Error inesperado en el proceso: {unexpected_error}"}],
            }

        # Actualizar UI al finalizar
        self.after(0, lambda: self._conversion_complete(results))

    def _update_progress(self, current, total, message):
        """Actualiza la barra de progreso."""
        progress = current / total
        self.progress_bar.set(progress)
        self.progress_label.configure(text=f"{message} ({current}/{total})")

    def _conversion_complete(self, results):
        """Maneja la finalización de la conversión."""
        self.is_processing = False
        self.progress_bar.set(1.0)

        # Restaurar botones
        self.convert_btn.configure(state="normal", text="🚀 Convertir a PDF")
        self.single_file_btn.configure(state="normal")
        self.multiple_files_btn.configure(state="normal")
        self.clear_files_btn.configure(state="normal")
        self.output_btn.configure(state="normal")

        converted = results["converted"]
        errors = results["errors"]
        ignored = results["skipped"]

        # Mostrar resultado
        success_count = len(converted)
        error_count = len(errors)
        ignored_count = len(ignored)

        msg_header = "✅ Conversión completada" if error_count == 0 else "⚠️ Conversión parcial"
        status_text = f"{msg_header}: {success_count} éxitos"
        if error_count > 0:
            status_text += f", {error_count} errores"
        if ignored_count > 0:
            status_text += f" ({ignored_count} omitidos)"

        self.progress_label.configure(text=status_text)

        # Mensaje de información detallado
        info_msg = f"Se han procesado {success_count} archivo(s) exitosamente."

        # Mostrar motor usado
        browser_count = sum(1 for item in converted if item["engine"] == "browser")
        xhtml_count = sum(1 for item in converted if item["engine"] == "xhtml2pdf")
        if browser_count > 0 and xhtml_count > 0:
            info_msg += f"\n\n🔧 Motor: {browser_count} con Chromium, {xhtml_count} con xhtml2pdf (fallback)"
        elif browser_count > 0:
            info_msg += f"\n\n🔧 Motor: Chromium"
        elif xhtml_count > 0:
            info_msg += f"\n\n🔧 Motor: xhtml2pdf (fallback)"

        if ignored_count > 0:
            boleta_names = "\n".join(f"• {Path(item['xml']).name}" for item in ignored[:5])
            if ignored_count > 5:
                boleta_names += f"\n... y {ignored_count - 5} más"
            info_msg += (
                f"\n\n⚠️ ADVERTENCIA - Boletas detectadas ({ignored_count}):\n"
                f"{boleta_names}\n"
                "Las boletas de venta NO fueron convertidas. "
                "Esta aplicación solo procesa facturas y notas de crédito."
            )

        if error_count > 0:
            error_lines = []
            for item in errors[:5]:
                name = Path(item["xml"]).name if item["xml"] else "Proceso"
                error_lines.append(f"{name}: {item['error']}")
            error_msg = "\n".join(error_lines)
            if error_count > 5:
                error_msg += f"\n... y {error_count - 5} errores más"
            info_msg += f"\n\nErrores encontrados:\n{error_msg}"
            info_msg += f"\n\n(Detalle completo en logs/factura_converter.log)"

        if error_count == 0 and ignored_count == 0:
            messagebox.showinfo("Éxito", info_msg)
        else:
            messagebox.showwarning("Proceso Finalizado", info_msg)


def main():
    """Punto de entrada de la aplicación."""
    configure_logging()
    app = FacturaConverterApp()
    app.mainloop()


if __name__ == "__main__":
    main()
