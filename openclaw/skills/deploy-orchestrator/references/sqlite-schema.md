# SQLite schema reference

This skill expects the SQLite schema documented in:
- `/home/ice147ender/.openclaw/workspace/state/UTH_DTDM/docs/sqlite-state-schema-v1.md`

For convenience, the runtime bootstrap script creates these tables:
- `deployment_state`
- `deployment_history`
- `deployment_lock`

The Python init script is the executable source of truth for table creation.
