# SQLite schema reference

This skill expects the SQLite deploy-state schema documented for this project.

For convenience, the runtime bootstrap script creates these tables:
- `deployment_state`
- `deployment_history`
- `deployment_lock`

The Python init script is the executable source of truth for table creation.
