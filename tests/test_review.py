#!/usr/bin/env python3
"""Review scope, false-positive, and stale-artifact regression contracts."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / 'scripts/review-evidence.py'


class ReviewTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.write('README.md', 'fixture\n')
        self.write('.erixpo/stack.md', 'check: test -f README.md\n')
        self.git('init', '-q')
        self.git('config', 'user.email', 'fixture@example.com')
        self.git('config', 'user.name', 'Fixture')
        self.git('add', 'README.md')
        self.git('commit', '-qm', 'initial')
        self.base = self.git('rev-parse', 'HEAD').strip()

    def tearDown(self):
        self.tmp.cleanup()

    def write(self, name, content):
        p = self.root / name
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content)

    def git(self, *args):
        return subprocess.check_output(['git', '-C', str(self.root), *args], text=True)

    def run_review(self):
        return subprocess.run(['python3', str(HELPER), 'review', '--root', str(self.root)], env=dict(os.environ, ERIXPO_REVIEW_BASE=self.base), capture_output=True, text=True)

    def verify(self):
        return subprocess.run(['python3', str(HELPER), 'verify', '--root', str(self.root), '--base', self.base], capture_output=True, text=True)

    def test_owned_pack_and_symlink_not_scanned(self):
        self.write('.agents/skills/erixpo/SKILL.md', 'TODO: implement\nlorem ipsum\n')
        self.write('.agents/skills/erixpo/example.py', 'assert True\n')
        self.write('.erixpo/install-manifest.txt', '.agents/skills/erixpo\n')
        (self.root / 'scripts').symlink_to('.agents/skills/erixpo', target_is_directory=True)
        result = self.run_review()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_actual_installed_project_passes(self):
        installed = subprocess.run(["bash", str(ROOT / "install.sh"), "--target", str(self.root), "--host", "generic"], capture_output=True, text=True)
        self.assertEqual(installed.returncode, 0, installed.stdout + installed.stderr)
        result = self.run_review()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_untracked_product_requires_tests_and_false_test_name_rejected(self):
        self.write('src/contest.py', 'print(123)\n')
        result = self.run_review()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('no test/spec', result.stdout)
        self.write('tests/test_contest.py', 'assert 1 + 1 == 2\n')
        self.assertEqual(self.run_review().returncode, 0)

    def test_newline_filename_and_untracked_secret(self):
        self.write('src/app\nmodule.py', 'print(123)\n')
        self.write('tests/test_app.py', 'assert 1 + 1 == 2\n')
        self.write('credential\nfile.txt', 'ghp_' + 'a' * 30)
        result = self.run_review()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('secret-looking content', result.stdout)

    def test_fresh_then_stale_evidence(self):
        self.assertEqual(self.run_review().returncode, 0)
        e = json.loads((self.root / '.erixpo/REVIEW-stage1.json').read_text())
        self.write('.erixpo/REVIEW.md', 'Result: ship\nReview-ID: ' + e['review_id'] + '\nReviewer: test-fixture\n')
        self.assertEqual(self.verify().returncode, 0)
        self.write('README.md', 'changed\n')
        self.assertNotEqual(self.verify().returncode, 0)
        self.assertEqual(self.run_review().returncode, 0)
        self.assertNotEqual(self.verify().returncode, 0, 'old stage-2 must not authorize a new review')

    def test_reviewer_identity_required(self):
        self.assertEqual(self.run_review().returncode, 0)
        e = json.loads((self.root / '.erixpo/REVIEW-stage1.json').read_text())
        self.write('.erixpo/REVIEW.md', 'Result: ship\nReview-ID: ' + e['review_id'] + '\nReviewer:\nDate: today\n')
        result = self.verify()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Reviewer identity is required', result.stderr)

    def test_changed_check_invalidates_evidence(self):
        self.assertEqual(self.run_review().returncode, 0)
        e = json.loads((self.root / '.erixpo/REVIEW-stage1.json').read_text())
        self.write('.erixpo/REVIEW.md', 'Result: ship\nReview-ID: ' + e['review_id'] + '\nReviewer: test-fixture\n')
        self.write('.erixpo/stack.md', 'check: test -d .erixpo\n')
        self.assertNotEqual(self.verify().returncode, 0)

    def test_check_mutating_reviewed_files_rejected(self):
        self.write('.erixpo/stack.md', 'check: echo changed >> README.md\n')
        self.assertIn('project changed during review', self.run_review().stdout)

    def test_non_git_scope_still_checks_secrets_and_source(self):
        import shutil
        shutil.rmtree(self.root / '.git')
        self.base = ''
        self.write('app.py', 'print(123)\n')
        self.write('.env', 'EXAMPLE=value\n')
        result = self.run_review()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('secret-looking file', result.stdout)
        self.assertIn('no test/spec', result.stdout)


if __name__ == '__main__':
    unittest.main()
