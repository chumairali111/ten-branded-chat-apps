"""Feature package: one API endpoint handler per file."""
from ._shared import bp
from . import upload, download, media

from . import shared_media
