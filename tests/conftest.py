"""Configuración de pytest: asegura que 'src' sea importable desde cualquier cwd."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
