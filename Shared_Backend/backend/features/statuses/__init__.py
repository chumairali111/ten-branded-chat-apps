"""Feature package: one API endpoint handler per file."""
from ._shared import bp
from . import get, add, view, delete

from . import viewers
