#!/usr/bin/env python3
"""Opt-in paired artifact evaluation; commands are supplied explicitly, never installed."""
import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time

PACK = Path(__file__).resolve().parents[1]


def scenarios(directory):
    result = []
    for path in sorted(directory.glob('*/scenario.json')):
        data = json.loads(path.read_text())
        if not isinstance(data.get('id'), str) or not data.get('prompt') or not (path.parent / 'check.py').is_file() or not (path.parent / 'fixture').is_dir():
            raise ValueError('invalid scenario: ' + str(path))
        compile((path.parent / 'check.py').read_text(), str(path.parent / 'check.py'), 'exec')
        result.append((path.parent, data))
    if not result:
        raise ValueError('no scenarios found')
    if len({s['id'] for _, s in result}) != len(result):
        raise ValueError('scenario IDs must be unique')
    return result


def check(path, work, timeout):
    try:
        p = subprocess.run([sys.executable, str(path / 'check.py'), str(work)], capture_output=True, text=True, timeout=timeout)
        return p.returncode == 0, (p.stdout + p.stderr)[-4000:]
    except subprocess.TimeoutExpired:
        return False, 'artifact checker timed out'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--scenarios', type=Path, default=PACK / 'examples/evaluations')
    parser.add_argument('--dry-run', action='store_true', help='validate fixtures without invoking workers')
    parser.add_argument('--baseline-command', help='explicit shell command for the raw worker')
    parser.add_argument('--workflow-command', help='explicit shell command for the same worker through erixpo')
    parser.add_argument('--model', help='same model/version used in both commands; recorded, not inferred')
    parser.add_argument('--trials', type=int, default=1)
    parser.add_argument('--timeout', type=float, default=600)
    parser.add_argument('--output', type=Path, help='new result directory; refuses existing paths')
    args = parser.parse_args()
    if args.trials < 1 or args.timeout <= 0:
        parser.error('trials and timeout must be positive')
    suite = scenarios(args.scenarios.resolve())
    if args.dry_run:
        for path, scenario in suite:
            with tempfile.TemporaryDirectory(prefix='erixpo-eval-validate-') as directory:
                work = Path(directory) / 'work'
                shutil.copytree(path / 'fixture', work)
                passed, _ = check(path, work, min(args.timeout, 30))
                if passed:
                    raise ValueError('initial fixture already satisfies outcome: ' + scenario['id'])
            print('validated ' + scenario['id'])
        return 0
    if not args.baseline_command or not args.workflow_command or not args.model or not args.output:
        parser.error('live runs require --baseline-command, --workflow-command, --model, and --output')
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    records = []
    for path, scenario in suite:
        for trial in range(1, args.trials + 1):
            # Alternate order to reduce a consistent first-run advantage.
            modes = ('baseline', 'workflow') if trial % 2 else ('workflow', 'baseline')
            for mode in modes:
                run = output / f'{len(records) + 1:04d}-{mode}'
                work = run / 'work'
                shutil.copytree(path / 'fixture', work)
                prompt = run / 'prompt.txt'
                prompt.write_text(scenario['prompt'] + '\n')
                command = args.baseline_command if mode == 'baseline' else args.workflow_command
                env = dict(os.environ, ERIXPO_EVAL_PROMPT_FILE=str(prompt), ERIXPO_EVAL_MODEL=args.model, ERIXPO_EVAL_MODE=mode)
                start = time.monotonic()
                timed_out = False
                with (run / 'worker.log').open('w') as log, prompt.open() as stdin:
                    # A new process group lets timeout terminate child provider processes too.
                    worker = subprocess.Popen(['bash', '-c', command], cwd=work, env=env, stdin=stdin, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
                    try:
                        code = worker.wait(timeout=args.timeout)
                    except (subprocess.TimeoutExpired, KeyboardInterrupt) as interruption:
                        import signal
                        os.killpg(worker.pid, signal.SIGTERM)
                        try:
                            worker.wait(timeout=3)
                        except subprocess.TimeoutExpired:
                            os.killpg(worker.pid, signal.SIGKILL)
                            worker.wait()
                        if isinstance(interruption, KeyboardInterrupt):
                            raise
                        timed_out = True
                        code = worker.returncode
                elapsed = time.monotonic() - start
                complete, detail = check(path, work, min(args.timeout, 30))
                record = dict(scenario=scenario['id'], mode=mode, trial=trial, model=args.model,
                              pack_version=(PACK / 'VERSION').read_text().strip(), command=command,
                              completed=complete, worker_exit=code, timed_out=timed_out,
                              false_success=(code == 0 and not complete), elapsed_seconds=round(elapsed, 3),
                              user_interventions=None, cost_usd=None, human_score=None,
                              outcome_detail=detail, artifact_directory=str(work),
                              recorded_at=datetime.now(timezone.utc).isoformat())
                records.append(record)
                (output / 'results.json').write_text(json.dumps(records, indent=2) + '\n')
                print(f"{scenario['id']} {mode} trial={trial} completed={complete} false_success={record['false_success']}")
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (ValueError, OSError) as e:
        print(str(e), file=sys.stderr)
        sys.exit(1)
