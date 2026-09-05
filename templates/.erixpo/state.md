# state

# Canonical job state. Do not write new jobs to state.yaml.

phase: initialized
# initialized | planned | approved | building | review | done | blocked
job_type: unknown
plan: draft
# draft | approved
isolation: none
# none | worktree | in-place
ceremony: unknown
# full | standard | light
worktree_id:
# optional

# Runtime-owned fields; completion requires fresh verification.json evidence.
outcome: pending
# pending | running | slice_verified | plan_complete | worker_failed | check_failed | no_progress | blocked | interrupted | budget_exhausted
run_id:
iteration: 0
