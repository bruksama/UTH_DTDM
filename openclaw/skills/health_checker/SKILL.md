---
name: health_checker
description: Validate the candidate release before traffic is kept on the new version.
metadata:
  openclaw:
    os: ["linux"]
    requires:
      bins: ["curl"]
      config: []
---

# Health Checker

## Purpose

Confirm that the candidate environment is healthy before the deployment is finalized.
This skill is the validation gate between container startup and success or rollback.

## Inputs

- Candidate container endpoint
- Health check path and timeout policy
- Retry threshold
- Deployment context from `container_control`

## Responsibilities

1. Run health checks against the candidate environment.
2. Apply retry and timeout rules consistently.
3. Return a pass/fail result with evidence for the next step.

## Must Not Do

- Must not pull images or start containers
- Must not restore the previous environment directly
- Must not own final Slack reporting

## Outputs

- `healthy`: candidate is safe to be promoted to live traffic
- `unhealthy`: deployment must be rolled back

## Handoff

- On success: hand off to `container_control` for live traffic promotion
- On failure: hand off to `rollback_handler`
