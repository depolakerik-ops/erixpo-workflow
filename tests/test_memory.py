"""Effective append-only memory retrieval stays read-only and excludes tombstones."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SEARCH = ROOT / 'scripts/session-search.sh'


class MemoryTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='erixpo memory ')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.state = self.root / '.erixpo'
        self.state.mkdir()

    def write(self, kind, rows):
        (self.state / (kind + '.jsonl')).write_text(''.join(json.dumps(row) + '\n' for row in rows))

    def search(self, *args):
        return subprocess.run(['bash', str(SEARCH), '--root', str(self.root), *args], capture_output=True, text=True, check=True).stdout

    def test_latest_tombstone_hides_prior_matching_insight(self):
        for status in ['retracted', 'stale', 'quarantined']:
            with self.subTest(status=status):
                self.write('learnings', [
                    {'key': 'database', 'insight': 'Use obsolete SQLite workaround', 'status': 'active', 'ts': '2030-01-01'},
                    {'key': 'database', 'status': status, 'ts': '2020-01-01'},
                ])
                self.assertEqual(self.search('--kind', 'learnings', 'SQLite').strip(), 'no hits')
                self.assertEqual(self.search('--kind', 'learnings').strip(), 'no hits')

    def test_latest_correction_replaces_old_insight_before_matching(self):
        self.write('learnings', [
            {'key': 'stack', 'insight': 'Use Redis for caching', 'status': 'active'},
            {'key': 'stack', 'insight': 'Use local memory for caching', 'status': 'active'},
        ])
        self.assertEqual(self.search('--kind', 'learnings', 'Redis').strip(), 'no hits')
        out = self.search('--kind', 'learnings', 'caching')
        self.assertEqual(out.count('Prior learning:'), 1)
        self.assertIn('local memory', out)
        self.assertNotIn('applied', out)

    def test_explicit_reactivation_returns_only_latest_insight(self):
        self.write('learnings', [
            {'key': 'path', 'insight': 'old rule'},
            {'key': 'path', 'status': 'retracted'},
            {'key': 'path', 'insight': 'new verified rule', 'status': 'active'},
        ])
        out = self.search('--kind', 'learnings')
        self.assertIn('new verified rule', out)
        self.assertNotIn('old rule', out)

    def test_malformed_rows_and_fields_do_not_crash_or_resurrect(self):
        data = [
            {'key': 'gone', 'insight': 'unsafe old fact'},
            {'key': 'gone', 'status': 'retracted'},
            {'key': [], 'insight': 'bad key'},
            {'key': 'okay', 'insight': 'use current docs', 'files': 12, 'ts': {}, 'confidence': []},
            {'key': 'control', 'insight': 'docs\nline\x1b[31m\ud800'},
            ['not', 'a', 'record'], None,
        ]
        self.write('learnings', data)
        with (self.state / 'learnings.jsonl').open('ab') as out:
            out.write(b'{broken\n\xff\n')
        out = self.search('--kind', 'learnings', 'docs')
        self.assertIn('use current docs', out)
        self.assertNotIn('unsafe old fact', out)
        self.assertEqual(self.search('--kind', 'learnings', 'unsafe').strip(), 'no hits')

    def test_phrase_and_file_relevance_then_recency(self):
        self.write('learnings', [
            {'key': 'low', 'insight': 'invoice unrelated', 'ts': '2030-01-01'},
            {'key': 'high', 'insight': 'invoice parsing rules', 'files': ['src/invoice-parser.py'], 'ts': '2020-01-01'},
            {'key': 'tie-old', 'insight': 'common convention', 'ts': '2020-01-01'},
            {'key': 'tie-new', 'insight': 'common convention', 'ts': '2030-01-01'},
        ])
        self.assertIn('high', self.search('--kind', 'learnings', 'invoice parsing').splitlines()[0])
        self.assertIn('high', self.search('--kind', 'learnings', 'invoice-parser.py').splitlines()[0])
        self.assertIn('tie-new', self.search('--kind', 'learnings', 'common').splitlines()[0])

    def test_run_events_deduplicate_before_query_matching(self):
        self.write('sessions', [{'id': 'r1', 'goal': 'old SQLite attempt'}, {'id': 'r1', 'goal': 'verified local memory'}])
        events = self.state / 'run-events'
        events.mkdir()
        (events / 'r1.json').write_text(json.dumps({'id': 'r1', 'goal': 'old SQLite attempt'}))
        (events / 'r2.json').write_text(json.dumps({'id': 'r2', 'goal': 'unique completed run'}))
        (events / 'broken.json').write_text('{broken')
        self.assertEqual(self.search('--kind', 'sessions', 'SQLite').strip(), 'no hits')
        out = self.search('--kind', 'sessions')
        self.assertEqual(out.count('Prior session: r1'), 1)
        self.assertIn('unique completed run', out)

    def test_worktree_latest_status_is_not_mislabeled_live(self):
        self.write('worktrees', [{'id': 'tree1', 'status': 'live'}, {'id': 'tree1', 'status': 'closed'}])
        out = self.search('--kind', 'worktrees')
        self.assertEqual(out.count('tree1'), 1)
        self.assertIn('[closed]', out)
        self.assertNotIn('Live worktree:', out)

    def test_search_never_changes_files_and_limits_results(self):
        self.write('learnings', [{'key': str(i), 'insight': 'verified insight'} for i in range(12)])
        before = {str(p): (p.read_bytes(), p.stat().st_mtime_ns) for p in self.state.rglob('*') if p.is_file()}
        out = self.search()
        self.assertEqual(len(out.splitlines()), 8)
        after = {str(p): (p.read_bytes(), p.stat().st_mtime_ns) for p in self.state.rglob('*') if p.is_file()}
        self.assertEqual(before, after)

    def test_symlinked_memory_is_not_recalled(self):
        external = self.root / 'external.jsonl'
        external.write_text(json.dumps({'key': 'outside', 'insight': 'do not recall'}) + '\n')
        (self.state / 'learnings.jsonl').symlink_to(external)
        self.assertEqual(self.search('--kind', 'learnings').strip(), 'no hits')

    def test_session_can_be_found_by_verification_notes(self):
        self.write('sessions', [{'id': 'review-1', 'goal': 'Review', 'notes': 'keyboard trap fixed', 'check': 'pass'}])
        self.assertIn('review-1', self.search('--kind', 'sessions', 'keyboard trap'))

    def test_bad_options_fail_cleanly(self):
        for args in [('--root',), ('--kind',), ('--kind', 'unknown'), ('--unexpected',)]:
            result = subprocess.run(['bash', str(SEARCH), *args], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn('Traceback', result.stderr)
            self.assertNotIn('unbound variable', result.stderr)


if __name__ == '__main__':
    unittest.main()
