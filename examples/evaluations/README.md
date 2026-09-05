# Paired workflow evaluations

This is an opt-in framework, not evidence of live provider performance. The bundled fixtures cover an existing-code feature, CSV automation, native platform planning, and a writing artifact. They do not certify a complete native app or production deployment.

Validate the suite without workers or paid runs:

```sh
python3 scripts/evaluate-workflow.py --dry-run
```

Live runs require explicit commands and a model identifier. Use the **same provider/model/version and permissions** in both commands. The harness records your model label and exports `ERIXPO_EVAL_MODEL`; it cannot verify a provider's internal model selection. Configure the commands to honor it. For example, supply your own existing wrapper paths:

```sh
python3 scripts/evaluate-workflow.py \
  --baseline-command '/absolute/path/raw-worker-wrapper' \
  --workflow-command '/absolute/path/erixpo-worker-wrapper' \
  --model 'exact-provider-model-version' --trials 3 \
  --output /tmp/erixpo-evaluation-results
```

Each wrapper receives the task on stdin and in the file named by `ERIXPO_EVAL_PROMPT_FILE`; it runs inside a fresh fixture copy. The workflow wrapper should initialize erixpo and execute the task with the same worker as the baseline. No wrapper, provider, dependency, or pack is installed automatically. Commands execute with your normal permissions; fixture copies are isolation for comparison, not a security sandbox. Use only commands you intend to execute. Outputs may contain provider logs and generated artifacts, so inspect them before sharing.

Each mode/trial starts with identical files. The order alternates across trials. A worker exit of zero with failed artifact checks is recorded as `false_success`; `completed` means deterministic artifact checks passed, not that all subjective quality criteria were met. Results retain the command, model label, pack version, exit status, timeout, elapsed seconds, checker detail, and artifact location. Cost, interventions, and human score remain null until measured; null is not zero. Record actual user interventions and provider-reported cost after a run. Keep unsuccessful trials in the dataset.

Review artifacts blind to mode and score correctness, clarity, and task fit from 1–5. For writing, check unsupported claims, tone, and readability manually; for native planning, assess realistic macOS behavior and verification. The deterministic checks are deliberately narrow and do not replace this review. Compare completion and false-success rates, median elapsed time, interventions, costs where available, and human scores over repeated paired trials. Keep the raw results and model/version configuration with any published claim.

To add a scenario, create `scenario.json` with a unique `id` and `prompt`, an initial `fixture/` directory, and a standard-library `check.py` accepting the artifact directory as its first argument. Checks should test externally observable outcomes and exit nonzero for the initial fixture. Never put the answer inside the fixture.
