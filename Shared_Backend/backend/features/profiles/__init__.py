"""Feature package: one API endpoint handler per file."""
from ._shared import bp
from . import users, update, blocks, blocked

from . import avatar
