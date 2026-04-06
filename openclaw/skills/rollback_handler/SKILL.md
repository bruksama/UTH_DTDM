---
name: rollback_handler
description: Restore the previous live version when deployment validation or startup fails.
metadata:
  openclaw:
    os: ["linux"]
    requires:
      bins: ["docker"]
      config: []
---

# Rollback Handler

## Purpose

Recover service safely when the candidate release cannot stay live.
This skill owns traffic restoration and previous-version recovery after deployment failure.

## Inputs

- Failure reason from `container_control` or `health_checker`
- Previous active environment details
- Candidate environment details

## Responsibilities

1. Stop or isolate the failed candidate environment.
2. Restore traffic to the last known good version.
3. Preserve enough failure context for diagnosis.
4. Hand off rollback results to `log_analyzer`.

## Must Not Do

- Must not decide whether to deploy
- Must not re-run the health policy itself
- Must not be the final owner of user-facing result summaries

## Outputs

- `rollback_complete`: previous version restored
- `rollback_failed`: recovery attempt needs urgent operator attention

## Handoff

- Always hand off the final rollback context to `log_analyzer`
