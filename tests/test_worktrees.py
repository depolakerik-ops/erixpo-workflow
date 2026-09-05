#!/usr/bin/env python3
"""Regression contracts for worktree lifecycle using disposable repositories."""
import concurrent.futures
import fcntl
import os
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts' / 'worktree.sh'


class Worktrees(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / 'repo with spaces'
        self.root.mkdir()
        self.git('init', '-b', 'main')
        self.git('config', 'user.email', 'test@example.invalid')
        self.git('config', 'user.name', 'Test')
        (self.root / 'file.txt').write_text('baseline\n')
        self.git('add', '.')
        self.git('commit', '-m', 'baseline')

    def git(self, *args, root=None):
        return subprocess.run(['git', '-C', str(root or self.root), *args], check=True, capture_output=True, text=True).stdout.strip()

    def run_cli(self, *args, ok=True):
        p = subprocess.run(['bash', str(SCRIPT), *args], cwd=self.root, text=True, capture_output=True)
        if ok:
            self.assertEqual(p.returncode, 0, p.stderr + p.stdout)
        else:
            self.assertNotEqual(p.returncode, 0, p.stdout)
        return p

    def isolate(self):
        output = self.run_cli('isolate', '--porcelain').stdout
        result = dict(line.split('=', 1) for line in output.splitlines() if '=' in line)
        return result['id'], Path(result['path'])

    def test_empty_close_and_origin(self):
        ident, child = self.isolate()
        rows = [json.loads(s) for s in (self.root / '.erixpo/worktrees.jsonl').read_text().splitlines()]
        self.assertEqual(rows[0]['origin_branch'], 'main')
        self.assertEqual(rows[0]['base_commit'], self.git('rev-parse', 'HEAD'))
        self.run_cli('close', '--id', ident)
        self.assertFalse(child.exists())
        self.assertFalse((self.root / '.erixpo/state.yaml').exists())

    def test_dirty_source_each_operation(self):
        for kind in ('unstaged', 'staged', 'untracked', 'ignored'):
            for command in ('close', 'prune', 'merge'):
                with self.subTest(kind=kind, command=command):
                    ident, child = self.isolate()
                    name = 'file.txt' if kind in ('staged', 'unstaged') else 'new file.txt'
                    (child / name).write_text('valuable changes\n')
                    if kind == 'staged':
                        self.git('add', name, root=child)
                    if kind == 'ignored':
                        (child / '.erixpo').mkdir(exist_ok=True)
                        self.git('config', 'core.excludesFile', str(child / '.erixpo/ignore'), root=child)
                        (child / '.erixpo/ignore').write_text('new file.txt\n')
                    self.run_cli(command, '--id', ident, ok=False)
                    self.assertEqual((child / name).read_text(), 'valuable changes\n')

    def test_reviews_required_for_changed_branch(self):
        ident, child = self.isolate()
        (child / 'file.txt').write_text('completed change\n')
        self.git('add', 'file.txt', root=child)
        self.git('commit', '-m', 'change', root=child)
        original = self.git('rev-parse', 'HEAD')
        self.run_cli('close', '--id', ident, ok=False)
        self.assertTrue(child.exists())
        self.assertEqual(original, self.git('rev-parse', 'HEAD'))
        self.run_cli('prune', '--id', ident, '--delete-branch', ok=False)
        self.assertTrue(child.exists())

    def test_memory_reconciled_and_archived(self):
        state = self.root / '.erixpo'
        state.mkdir()
        (state / 'USER.md').write_text('original preference')
        (state / 'sessions.jsonl').write_text('{"id":"base"}\n')
        ident, child = self.isolate()
        (child / '.erixpo/USER.md').write_text('updated preference')
        (child / '.erixpo/sessions.jsonl').write_text('{"id":"base"}\n{"id":"child"}\n')
        (state / 'sessions.jsonl').write_text('{"id":"base"}\n{"id":"parent"}\n')
        (child / '.erixpo/other-progress.md').write_text('progress retained')
        self.run_cli('close', '--id', ident)
        self.assertEqual((state / 'USER.md').read_text(), 'updated preference')
        self.assertEqual([json.loads(s)['id'] for s in (state / 'sessions.jsonl').read_text().splitlines()], ['base', 'parent', 'child'])
        self.assertEqual((state / 'worktree-archives' / ident / 'other-progress.md').read_text(), 'progress retained')

    def test_memory_conflict_refuses_removal(self):
        state = self.root / '.erixpo'
        state.mkdir()
        (state / 'MEMORY.md').write_text('original')
        ident, child = self.isolate()
        (state / 'MEMORY.md').write_text('parent edit')
        (child / '.erixpo/MEMORY.md').write_text('child edit')
        self.run_cli('close', '--id', ident, ok=False)
        self.assertTrue(child.exists())
        self.assertEqual((state / 'MEMORY.md').read_text(), 'parent edit')

    def test_wrong_origin_branch_refuses(self):
        ident, child = self.isolate()
        self.git('checkout', '-b', 'other')
        self.run_cli('close', '--id', ident, ok=False)
        self.assertTrue(child.exists())

    def test_parallel_registry_creation(self):
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
            futures = [pool.submit(self.isolate) for _ in range(4)]
            children = [f.result() for f in futures]
        rows = [json.loads(s) for s in (self.root / '.erixpo/worktrees.jsonl').read_text().splitlines()]
        self.assertEqual(len(rows), 4)
        self.assertEqual(len({r['id'] for r in rows}), 4)
        for ident, child in children:
            self.run_cli('close', '--id', ident)
            self.assertFalse(child.exists())

    def test_active_worker_refuses_close(self):
        ident, child = self.isolate()
        with (child / '.erixpo/run.lock').open('a') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            self.run_cli('close', '--id', ident, ok=False)
            self.assertTrue(child.exists())
        self.run_cli('close', '--id', ident)

    def test_reviewed_branch_lands_and_stale_review_refuses(self):
        for stale in (False, True):
            ident, child = self.isolate()
            (child / 'file.txt').write_text('reviewed change' + str(stale))
            self.git('add', 'file.txt', root=child)
            self.git('commit', '-m', 'change', root=child)
            (child / '.erixpo/stack.md').write_text('check: test -f file.txt\n')
            rows = [json.loads(s) for s in (self.root / '.erixpo/worktrees.jsonl').read_text().splitlines()]
            row = next(r for r in rows if r['id'] == ident)
            subprocess.run(['python3', str(SCRIPT.with_name('review-evidence.py')), 'review', '--root', str(child)],
                           env=dict(os.environ, ERIXPO_REVIEW_BASE=row['base_commit']), check=True, capture_output=True)
            evidence = json.loads((child / '.erixpo/REVIEW-stage1.json').read_text())
            (child / '.erixpo/REVIEW.md').write_text('Result: ship\nReview-ID: ' + evidence['review_id'] + '\nReviewer: test-fixture\n')
            if stale:
                (child / 'file.txt').write_text('unreviewed change')
                self.git('add', 'file.txt', root=child)
                self.git('commit', '-m', 'after review', root=child)
                self.run_cli('close', '--id', ident, ok=False)
                self.assertTrue(child.exists())
            else:
                self.run_cli('close', '--id', ident)
                self.assertFalse(child.exists())
                self.assertEqual((self.root / 'file.txt').read_text(), 'reviewed changeFalse')

    def test_isolation_preserves_feature_branch_review_base(self):
        self.git('checkout', '-b', 'feature')
        (self.root / 'file.txt').write_text('feature base')
        self.git('add', 'file.txt')
        self.git('commit', '-m', 'feature baseline')
        expected = self.git('rev-parse', 'HEAD')
        ident, child = self.isolate()
        metadata = json.loads((child / '.erixpo/isolation.json').read_text())
        self.assertEqual(metadata['base_commit'], expected)
        (child / 'file.txt').write_text('feature completed')
        self.git('add', 'file.txt', root=child)
        self.git('commit', '-m', 'work', root=child)
        (child / '.erixpo/stack.md').write_text('check: test -f file.txt\n')
        subprocess.run(['python3', str(SCRIPT.with_name('review-evidence.py')), 'review', '--root', str(child)],
                       check=True, capture_output=True)
        evidence = json.loads((child / '.erixpo/REVIEW-stage1.json').read_text())
        self.assertEqual(evidence['base'], expected)
        (child / '.erixpo/REVIEW.md').write_text('Result: ship\nReview-ID: ' + evidence['review_id'] + '\nReviewer: test-fixture\n')
        self.run_cli('close', '--id', ident)
        self.assertFalse(child.exists())

    def test_installed_host_skills_survive_isolation(self):
        subprocess.run(['bash', str(SCRIPT.parents[1] / 'install.sh'), '--host', 'generic', '--target', str(self.root)],
                       check=True, capture_output=True)
        ident, child = self.isolate()
        skill = '.agents/skills/erixpo/SKILL.md'
        self.assertEqual((child / skill).read_bytes(), (self.root / skill).read_bytes())
        self.assertTrue(os.access(child / '.erixpo/bin/erixpo', os.X_OK))
        subprocess.run([str(child / '.erixpo/bin/erixpo'), '--help'], cwd=child, check=True, capture_output=True)
        self.run_cli('close', '--id', ident)
        self.assertFalse(child.exists())
        self.assertTrue((self.root / skill).exists())

    def test_modified_installed_child_skill_is_preserved(self):
        subprocess.run(['bash', str(SCRIPT.parents[1] / 'install.sh'), '--host', 'generic', '--target', str(self.root)],
                       check=True, capture_output=True)
        ident, child = self.isolate()
        skill = child / '.agents/skills/erixpo/SKILL.md'
        skill.write_text(skill.read_text() + '\nUser correction\n')
        self.run_cli('close', '--id', ident, ok=False)
        self.assertTrue(skill.read_text().endswith('User correction\n'))

    def test_conflicting_event_identity_refuses(self):
        state = self.root / '.erixpo'
        state.mkdir()
        (state / 'sessions.jsonl').write_text('{"id":"same","value":"baseline"}\n')
        ident, child = self.isolate()
        (child / '.erixpo/sessions.jsonl').write_text('{"id":"same","value":"changed"}\n')
        self.run_cli('close', '--id', ident, ok=False)
        self.assertTrue(child.exists())
        self.assertEqual(json.loads((state / 'sessions.jsonl').read_text())['value'], 'baseline')

    def test_run_events_reconciled(self):
        ident, child = self.isolate()
        events = child / '.erixpo/run-events'
        events.mkdir()
        payload = '{"id":"worker-session","outcome":"plan_complete"}\n'
        (events / 'worker-session.json').write_text(payload)
        self.run_cli('close', '--id', ident)
        self.assertEqual((self.root / '.erixpo/run-events/worker-session.json').read_text(), payload)

    def test_git_refused_removal_restores_metadata_and_can_retry(self):
        ident, child = self.isolate()
        (child / '.erixpo/MEMORY.md').write_text('valuable child learning')
        self.git('worktree', 'lock', str(child))
        self.run_cli('close', '--id', ident, ok=False)
        self.assertEqual((child / '.erixpo/MEMORY.md').read_text(), 'valuable child learning')
        self.git('worktree', 'unlock', str(child))
        self.run_cli('close', '--id', ident)
        self.assertFalse(child.exists())
        self.assertEqual((self.root / '.erixpo/MEMORY.md').read_text(), 'valuable child learning')

    def test_project_skill_and_refinement_survive_close_and_next_isolation(self):
        ident, child = self.isolate()
        recipe = child / '.erixpo/skills/local-recipe'
        recipe.mkdir(parents=True)
        skill = '---\nname: local-recipe\ndescription: Local procedure\nstatus: quarantined\n---\nApproved inputs only.\n'
        (recipe / 'SKILL.md').write_text(skill)
        (recipe / 'status.json').write_text('{"status":"quarantined","successful_uses":0}\n')
        (recipe / 'run.sh').write_text('#!/bin/sh\necho example\n')
        (recipe / 'run.sh').chmod(0o755)
        log = 'Recipe local-recipe drafted; status: quarantined; rollback: remove recipe.\n'
        (child / '.erixpo/refine-log.md').write_text(log)
        self.run_cli('close', '--id', ident)
        self.assertEqual((self.root / '.erixpo/refine-log.md').read_text(), log)
        self.assertEqual((self.root / '.erixpo/skills/local-recipe/SKILL.md').read_text(), skill)
        self.assertEqual(json.loads((self.root / '.erixpo/skills/local-recipe/status.json').read_text())['status'], 'quarantined')
        self.assertTrue(os.access(self.root / '.erixpo/skills/local-recipe/run.sh', os.X_OK))
        next_ident, next_child = self.isolate()
        self.assertEqual((next_child / '.erixpo/refine-log.md').read_text(), log)
        self.assertEqual((next_child / '.erixpo/skills/local-recipe/SKILL.md').read_text(), skill)
        self.run_cli('close', '--id', next_ident)

    def test_project_recipe_and_refine_log_conflicts_preserved(self):
        for name in ('skills/local-recipe/SKILL.md', 'skills/local-recipe/status.json', 'refine-log.md'):
            with self.subTest(name=name):
                target = self.root / '.erixpo' / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text('baseline')
                ident, child = self.isolate()
                target.write_text('parent change')
                theirs = child / '.erixpo' / name
                theirs.write_text('child change')
                self.run_cli('close', '--id', ident, ok=False)
                self.assertEqual(target.read_text(), 'parent change')
                self.assertEqual(theirs.read_text(), 'child change')
                target.write_text('child change')
                self.run_cli('close', '--id', ident)

    def test_project_recipe_unilateral_updates_and_deletions(self):
        recipe = self.root / '.erixpo/skills/local-recipe'
        recipe.mkdir(parents=True)
        (recipe / 'SKILL.md').write_text('baseline quarantined recipe')
        (recipe / 'obsolete.md').write_text('obsolete notes')
        ident, child = self.isolate()
        (child / '.erixpo/skills/local-recipe/SKILL.md').write_text('revised quarantined recipe')
        (child / '.erixpo/skills/local-recipe/obsolete.md').unlink()
        self.run_cli('close', '--id', ident)
        self.assertEqual((recipe / 'SKILL.md').read_text(), 'revised quarantined recipe')
        self.assertFalse((recipe / 'obsolete.md').exists())

    def test_divergent_learning_status_refuses_close(self):
        state = self.root / '.erixpo'
        state.mkdir()
        baseline = {'key': 'shared', 'status': 'active', 'insight': 'baseline'}
        (state / 'learnings.jsonl').write_text(json.dumps(baseline) + '\n')
        ident, child = self.isolate()
        parent = [baseline, {'key': 'shared', 'status': 'retracted', 'insight': 'wrong lesson'}]
        branch = [baseline, {'key': 'shared', 'status': 'active', 'insight': 'child revision'}]
        (state / 'learnings.jsonl').write_text(''.join(json.dumps(r) + '\n' for r in parent))
        (child / '.erixpo/learnings.jsonl').write_text(''.join(json.dumps(r) + '\n' for r in branch))
        self.run_cli('close', '--id', ident, ok=False)
        self.assertTrue(child.exists())
        self.assertEqual(json.loads((state / 'learnings.jsonl').read_text().splitlines()[-1])['status'], 'retracted')

    def test_independent_learning_keys_preserve_effective_status(self):
        state = self.root / '.erixpo'
        state.mkdir()
        baseline = [{'key': 'parent-key', 'status': 'active'}, {'key': 'child-key', 'status': 'quarantined'}]
        (state / 'learnings.jsonl').write_text(''.join(json.dumps(r) + '\n' for r in baseline))
        ident, child = self.isolate()
        parent = baseline + [{'key': 'parent-key', 'status': 'retracted'}]
        branch = baseline + [{'key': 'child-key', 'status': 'active'}]
        (state / 'learnings.jsonl').write_text(''.join(json.dumps(r) + '\n' for r in parent))
        (child / '.erixpo/learnings.jsonl').write_text(''.join(json.dumps(r) + '\n' for r in branch))
        self.run_cli('close', '--id', ident)
        effective = {r['key']: r for r in map(json.loads, (state / 'learnings.jsonl').read_text().splitlines())}
        self.assertEqual(effective['parent-key']['status'], 'retracted')
        self.assertEqual(effective['child-key']['status'], 'active')

    def test_shared_final_learning_does_not_replay_intermediate_active(self):
        state = self.root / '.erixpo'
        state.mkdir()
        baseline = {'key': 'shared', 'status': 'active', 'insight': 'baseline'}
        (state / 'learnings.jsonl').write_text(json.dumps(baseline) + '\n')
        ident, child = self.isolate()
        final = {'key': 'shared', 'status': 'retracted'}
        parent = [baseline, final]
        branch = [baseline, {'key': 'shared', 'status': 'active', 'insight': 'intermediate'}, final]
        (state / 'learnings.jsonl').write_text(''.join(json.dumps(r) + '\n' for r in parent))
        (child / '.erixpo/learnings.jsonl').write_text(''.join(json.dumps(r) + '\n' for r in branch))
        self.run_cli('close', '--id', ident)
        effective = json.loads((state / 'learnings.jsonl').read_text().splitlines()[-1])
        self.assertEqual(effective['status'], 'retracted')

    def test_identical_historical_learning_can_be_reactivated(self):
        state = self.root / '.erixpo'
        state.mkdir()
        active = {'key': 'shared', 'status': 'active', 'insight': 'original lesson'}
        retracted = {'key': 'shared', 'status': 'retracted', 'insight': 'original lesson'}
        baseline = [active, retracted]
        (state / 'learnings.jsonl').write_text(''.join(json.dumps(r) + '\n' for r in baseline))
        ident, child = self.isolate()
        (child / '.erixpo/learnings.jsonl').write_text(''.join(json.dumps(r) + '\n' for r in baseline + [active]))
        self.run_cli('close', '--id', ident)
        effective = json.loads((state / 'learnings.jsonl').read_text().splitlines()[-1])
        self.assertEqual(effective, active)

    def test_corrupt_registry_is_preserved(self):
        state = self.root / '.erixpo'
        state.mkdir()
        (state / 'worktrees.jsonl').write_text('{broken\n')
        self.run_cli('isolate', ok=False)
        self.assertEqual((state / 'worktrees.jsonl').read_text(), '{broken\n')


if __name__ == '__main__':
    unittest.main()
