"""Feature package: one API endpoint handler per file."""
from ._shared import bp
from . import update, add, change, remove, history, reset, join, qr, similar
