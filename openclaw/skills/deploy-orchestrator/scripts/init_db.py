#!/usr/bin/env python3
import sqlite3
import sys
from pathlib import Path

if len(sys.argv) != 2:
    print("usage: init_db.py <sqlite_path>", file=sys.stderr)
    sys.exit(1)

path = Path(sys.argv[1])
path.parent.mkdir(parents=True, exist_ok=True)
conn = sqlite3.connect(path)
cur = conn.cursor()

cur.executescript(
    """
    CREATE TABLE IF NOT EXISTS deployment_state (
      environment TEXT PRIMARY KEY,
      active_color TEXT CHECK (active_color IN ('blue', 'green')),
      active_image_tag TEXT,
      active_image_digest TEXT,
      active_container_name TEXT,
      previous_color TEXT CHECK (previous_color IN ('blue', 'green')),
      previous_image_tag TEXT,
      previous_image_digest TEXT,
      last_deployment_id TEXT,
      status TEXT NOT NULL CHECK (status IN ('active', 'deploying', 'rollback-required', 'error')),
      updated_at TEXT NOT NULL,
      notes TEXT
    );

    CREATE TABLE IF NOT EXISTS deployment_history (
      deployment_id TEXT PRIMARY KEY,
      environment TEXT NOT NULL,
      requested_by TEXT NOT NULL,
      requested_command TEXT NOT NULL,
      requested_image TEXT NOT NULL,
      resolved_image_tag TEXT,
      resolved_image_digest TEXT,
      previous_active_color TEXT CHECK (previous_active_color IN ('blue', 'green')),
      candidate_color TEXT CHECK (candidate_color IN ('blue', 'green')),
      final_active_color TEXT CHECK (final_active_color IN ('blue', 'green')),
      health_check_url TEXT,
      health_check_passed INTEGER NOT NULL DEFAULT 0,
      rollback_occurred INTEGER NOT NULL DEFAULT 0,
      status TEXT NOT NULL CHECK (status IN ('pending', 'running', 'succeeded', 'failed', 'rolled_back', 'rollback_failed')),
      error_summary TEXT,
      operator_summary TEXT,
      started_at TEXT NOT NULL,
      finished_at TEXT
    );

    CREATE TABLE IF NOT EXISTS deployment_lock (
      environment TEXT PRIMARY KEY,
      locked_by TEXT NOT NULL,
      deployment_id TEXT NOT NULL,
      lock_reason TEXT,
      locked_at TEXT NOT NULL,
      expires_at TEXT
    );

    CREATE INDEX IF NOT EXISTS idx_history_environment_started_at
    ON deployment_history(environment, started_at DESC);

    CREATE INDEX IF NOT EXISTS idx_history_status
    ON deployment_history(status);
    """
)

conn.commit()
conn.close()
print(path)
