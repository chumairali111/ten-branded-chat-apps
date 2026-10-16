import sqlite3
from flask import g,current_app
from pathlib import Path

def db():
    if 'db' not in g:
        g.db=sqlite3.connect(current_app.config['DATABASE'],timeout=15)
        g.db.row_factory=sqlite3.Row
        g.db.execute('PRAGMA foreign_keys=ON')
        g.db.execute('PRAGMA journal_mode=WAL')
    return g.db

def rows(sql,args=()): return [dict(r) for r in db().execute(sql,args).fetchall()]
def one(sql,args=()):
    r=db().execute(sql,args).fetchone()
    return dict(r) if r else None

def run(sql,args=()):
    c=db().execute(sql,args);db().commit();return c.lastrowid

def init_db():
    cx=db()
    cx.executescript(Path(__file__).with_name('schema.sql').read_text())
    columns={row['name'] for row in cx.execute('PRAGMA table_info(sessions)').fetchall()}
    for name,definition in (
        ('id','TEXT'),
        ('device_name',"TEXT DEFAULT 'Browser'"),
        ('platform',"TEXT DEFAULT 'web'"),
        ('created','REAL DEFAULT 0'),
    ):
        if name not in columns:
            cx.execute(f'ALTER TABLE sessions ADD COLUMN {name} {definition}')
    cx.execute("UPDATE sessions SET id=lower(hex(randomblob(16))) WHERE id IS NULL")
    cx.execute("UPDATE sessions SET created=expires-604800 WHERE created=0 OR created IS NULL")
    cx.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_sessions_id ON sessions(id)')
    for table, additions in {
        'statuses': [('media_id', 'TEXT'), ('kind', "TEXT DEFAULT 'text'")],
        'status_views': [('viewed_at', 'REAL DEFAULT 0')],
    }.items():
        existing = {row['name'] for row in cx.execute(f'PRAGMA table_info({table})')}
        for name, definition in additions:
            if name not in existing:
                cx.execute(f'ALTER TABLE {table} ADD COLUMN {name} {definition}')
    cx.commit()
def close_db(e=None):
    c=g.pop('db',None)
    if c: c.close()
