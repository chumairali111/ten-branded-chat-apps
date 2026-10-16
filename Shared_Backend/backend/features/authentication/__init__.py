"""Feature package: one API endpoint handler per file."""
from ._shared import bp
from . import register, login, me, logout, sessions, revoke_sessions, device_pairings
