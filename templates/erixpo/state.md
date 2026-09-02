# state

# Canonical job state. Do not write new jobs to state.yaml.

phase: initialized
# initialized | planned | approved | building | review | done
job_type: unknown
plan: draft
# draft | approved
isolation: none
# none | worktree | in-place
ceremony: unknown
# full | standard | light
worktree_id:
# optional
