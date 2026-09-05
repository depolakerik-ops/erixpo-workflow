#!/usr/bin/env python3
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
HARNESS = ROOT / 'scripts/evaluate-workflow.py'


class EvaluationTests(unittest.TestCase):
    def test_bundled_fixtures_validate_without_worker(self):
        result = subprocess.run([sys.executable, str(HARNESS), '--dry-run'], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.count('validated '), 4)

    def test_paired_outcomes_and_false_success(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            scenario = root / 'scenarios/tiny'
            (scenario / 'fixture').mkdir(parents=True)
            (scenario / 'fixture/README.md').write_text('fixture')
            (scenario / 'scenario.json').write_text(json.dumps({'id': 'tiny', 'prompt': 'Create done.txt containing done.'}))
            (scenario / 'check.py').write_text('from pathlib import Path\nimport sys\nassert (Path(sys.argv[1]) / "done.txt").read_text() == "done"\n')
            result = subprocess.run([sys.executable, str(HARNESS), '--scenarios', str(root / 'scenarios'), '--baseline-command', 'true', '--workflow-command', "printf done > done.txt", '--model', 'fake-worker-v1', '--output', str(root / 'results')], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            rows = json.loads((root / 'results/results.json').read_text())
            self.assertEqual(len(rows), 2)
            self.assertTrue(rows[0]['false_success'])
            self.assertFalse(rows[0]['completed'])
            self.assertTrue(rows[1]['completed'])
            self.assertIsNone(rows[1]['cost_usd'])
            self.assertEqual(rows[0]['model'], rows[1]['model'])
            self.assertFalse((scenario / 'fixture/done.txt').exists())

    def test_live_commands_required(self):
        result = subprocess.run([sys.executable, str(HARNESS)], capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('live runs require', result.stderr)


if __name__ == '__main__':
    unittest.main()
