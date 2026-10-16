PRAGMA foreign_keys=ON;
CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY,username TEXT UNIQUE NOT NULL,name TEXT NOT NULL,password TEXT NOT NULL,about TEXT DEFAULT 'Available',avatar TEXT DEFAULT '',last_seen REAL DEFAULT 0);
CREATE TABLE IF NOT EXISTS sessions(token TEXT PRIMARY KEY,user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,csrf TEXT NOT NULL,expires REAL NOT NULL,id TEXT UNIQUE,device_name TEXT DEFAULT 'Browser',platform TEXT DEFAULT 'web',created REAL DEFAULT 0);
CREATE TABLE IF NOT EXISTS login_attempts(username TEXT PRIMARY KEY,count INTEGER DEFAULT 0,locked_until REAL DEFAULT 0);
CREATE TABLE IF NOT EXISTS device_pairings(id TEXT PRIMARY KEY,secret_hash TEXT NOT NULL,device_name TEXT NOT NULL,platform TEXT NOT NULL,status TEXT NOT NULL DEFAULT 'pending',account_id INTEGER REFERENCES users(id) ON DELETE CASCADE,session_token TEXT REFERENCES sessions(token) ON DELETE CASCADE,expires REAL NOT NULL,created REAL NOT NULL,delivered INTEGER NOT NULL DEFAULT 0,failed_attempts INTEGER NOT NULL DEFAULT 0);
CREATE TABLE IF NOT EXISTS device_pairing_events(id INTEGER PRIMARY KEY,pairing_id TEXT NOT NULL,account_id INTEGER REFERENCES users(id) ON DELETE SET NULL,event TEXT NOT NULL,created REAL NOT NULL);
CREATE TABLE IF NOT EXISTS chats(id INTEGER PRIMARY KEY,kind TEXT NOT NULL,title TEXT,description TEXT DEFAULT '',created_by INTEGER REFERENCES users(id),created REAL,invite TEXT UNIQUE,admin_only INTEGER DEFAULT 0,disappear INTEGER DEFAULT 0,advanced_privacy INTEGER DEFAULT 0,community_id INTEGER);
CREATE TABLE IF NOT EXISTS members(chat_id INTEGER REFERENCES chats(id) ON DELETE CASCADE,user_id INTEGER REFERENCES users(id),role TEXT DEFAULT 'member',tag TEXT DEFAULT '',PRIMARY KEY(chat_id,user_id));
CREATE TABLE IF NOT EXISTS preferences(chat_id INTEGER REFERENCES chats(id) ON DELETE CASCADE,user_id INTEGER REFERENCES users(id),favourite INTEGER DEFAULT 0,archived INTEGER DEFAULT 0,muted INTEGER DEFAULT 0,media_visible INTEGER DEFAULT 1,locked INTEGER DEFAULT 0,cleared REAL DEFAULT 0,last_read INTEGER DEFAULT 0,PRIMARY KEY(chat_id,user_id));
CREATE TABLE IF NOT EXISTS messages(id INTEGER PRIMARY KEY,chat_id INTEGER REFERENCES chats(id) ON DELETE CASCADE,sender INTEGER REFERENCES users(id),body TEXT DEFAULT '',kind TEXT DEFAULT 'text',file_id TEXT,reply_id INTEGER REFERENCES messages(id),created REAL,edited INTEGER DEFAULT 0,deleted INTEGER DEFAULT 0,expires REAL);
CREATE TABLE IF NOT EXISTS files(id TEXT PRIMARY KEY,chat_id INTEGER REFERENCES chats(id),owner INTEGER REFERENCES users(id),name TEXT,mime TEXT,size INTEGER,path TEXT);
CREATE TABLE IF NOT EXISTS hidden_messages(message_id INTEGER REFERENCES messages(id) ON DELETE CASCADE,user_id INTEGER REFERENCES users(id),PRIMARY KEY(message_id,user_id));
CREATE TABLE IF NOT EXISTS reactions(message_id INTEGER REFERENCES messages(id) ON DELETE CASCADE,user_id INTEGER REFERENCES users(id),emoji TEXT,PRIMARY KEY(message_id,user_id));
CREATE TABLE IF NOT EXISTS stars(message_id INTEGER REFERENCES messages(id) ON DELETE CASCADE,user_id INTEGER REFERENCES users(id),PRIMARY KEY(message_id,user_id));
CREATE TABLE IF NOT EXISTS typing(chat_id INTEGER REFERENCES chats(id),user_id INTEGER REFERENCES users(id),until REAL,PRIMARY KEY(chat_id,user_id));
CREATE TABLE IF NOT EXISTS blocks(user_id INTEGER REFERENCES users(id),blocked_id INTEGER REFERENCES users(id),PRIMARY KEY(user_id,blocked_id));
CREATE TABLE IF NOT EXISTS member_events(id INTEGER PRIMARY KEY,chat_id INTEGER REFERENCES chats(id),actor INTEGER REFERENCES users(id),detail TEXT,created REAL);
CREATE TABLE IF NOT EXISTS lists(id INTEGER PRIMARY KEY,user_id INTEGER REFERENCES users(id),name TEXT);
CREATE TABLE IF NOT EXISTS list_chats(list_id INTEGER REFERENCES lists(id) ON DELETE CASCADE,chat_id INTEGER REFERENCES chats(id),PRIMARY KEY(list_id,chat_id));
CREATE TABLE IF NOT EXISTS statuses(id INTEGER PRIMARY KEY,user_id INTEGER REFERENCES users(id),body TEXT,created REAL,expires REAL);
CREATE TABLE IF NOT EXISTS status_views(status_id INTEGER REFERENCES statuses(id),user_id INTEGER REFERENCES users(id),PRIMARY KEY(status_id,user_id));
CREATE TABLE IF NOT EXISTS communities(id INTEGER PRIMARY KEY,owner INTEGER REFERENCES users(id),name TEXT,description TEXT DEFAULT '');
CREATE TABLE IF NOT EXISTS reports(id INTEGER PRIMARY KEY,user_id INTEGER REFERENCES users(id),chat_id INTEGER REFERENCES chats(id),reason TEXT,created REAL);
CREATE INDEX IF NOT EXISTS idx_messages_chat ON messages(chat_id,id);
CREATE INDEX IF NOT EXISTS idx_members_user ON members(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_pairings_expiry ON device_pairings(expires,status);
CREATE INDEX IF NOT EXISTS idx_pairing_events_pairing ON device_pairing_events(pairing_id,created);


CREATE TABLE IF NOT EXISTS lock_grants(token TEXT REFERENCES sessions(token) ON DELETE CASCADE,chat_id INTEGER REFERENCES chats(id),expires REAL,PRIMARY KEY(token,chat_id));
CREATE TABLE IF NOT EXISTS calls(id INTEGER PRIMARY KEY,chat_id INTEGER REFERENCES chats(id),caller INTEGER REFERENCES users(id),callee INTEGER REFERENCES users(id),video INTEGER DEFAULT 0,state TEXT DEFAULT 'ringing',created REAL,updated REAL);
CREATE TABLE IF NOT EXISTS call_signals(id INTEGER PRIMARY KEY,call_id INTEGER REFERENCES calls(id),sender INTEGER REFERENCES users(id),payload TEXT,created REAL);

CREATE TABLE IF NOT EXISTS shared_media(id TEXT PRIMARY KEY,owner INTEGER REFERENCES users(id),purpose TEXT NOT NULL,name TEXT NOT NULL,mime TEXT NOT NULL,size INTEGER NOT NULL,path TEXT NOT NULL,created REAL NOT NULL);
