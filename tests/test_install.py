"""Installer lifecycle regressions using disposable target directories."""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('installer', ROOT / 'scripts/install-pack.py')
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


class InstallTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='erixpo install ')
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.target = self.base / 'project'
        self.target.mkdir()

    def install(self, *args, ok=True, env=None):
        result = subprocess.run(['bash', str(ROOT / 'install.sh'), '--target', str(self.target), '--host', 'generic', *args],
                                capture_output=True, text=True, env=env)
        if ok:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout)
        return result

    def snapshot(self, root=None):
        root = root or self.target
        return {str(p.relative_to(root)): ('link', os.readlink(p)) if p.is_symlink() else p.read_bytes() if p.is_file() else 'dir'
                for p in root.rglob('*')}

    def legacy_install(self, ref):
        import io
        import tarfile
        available = subprocess.run(['git', '-C', str(ROOT), 'cat-file', '-e', ref + '^{commit}'], capture_output=True)
        if available.returncode:
            self.skipTest('historical fixture commit is unavailable in this checkout: ' + ref)
        archive = subprocess.check_output(['git', '-C', str(ROOT), 'archive', ref])
        source = self.base / ('legacy-' + ref)
        source.mkdir()
        with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
            # Trusted local git commits; reject links/escaping paths explicitly.
            for member in tar.getmembers():
                self.assertFalse(member.issym() or member.islnk())
                self.assertFalse(Path(member.name).is_absolute() or '..' in Path(member.name).parts)
            tar.extractall(source, **({'filter': 'data'} if hasattr(tarfile, 'data_filter') else {}))
        subprocess.run(['bash', str(source / 'install.sh'), '--target', str(self.target), '--host', 'generic'],
                       capture_output=True, text=True, check=True)

    def test_actual_legacy_releases_upgrade_twice(self):
        import shutil
        for ref in ['3bd5c62', '984cd90', '6301007', '615961e']:
            with self.subTest(ref=ref):
                shutil.rmtree(self.target)
                self.target.mkdir()
                self.legacy_install(ref)
                memory = self.target / '.erixpo/MEMORY.md'
                memory.write_text('remember this')
                self.install()
                self.install()
                result = subprocess.run([str(self.target / 'bin/erixpo'), 'capabilities'], cwd=self.target,
                                        capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn('capabilities:', result.stdout)
                self.assertEqual(memory.read_text(), 'remember this')
                self.install('--uninstall')
                self.assertFalse((self.target / '.agents/skills/erixpo').exists())
                self.assertEqual(memory.read_text(), 'remember this')

    def test_modified_legacy_skill_is_not_overwritten(self):
        self.legacy_install('3bd5c62')
        skill = self.target / '.agents/skills/erixpo/SKILL.md'
        skill.write_text(skill.read_text() + '\nmy custom instructions\n')
        before = self.snapshot()
        self.install(ok=False)
        self.assertEqual(before, self.snapshot())
        self.install('--uninstall')
        self.assertIn('my custom instructions', skill.read_text())
        self.assertFalse((self.target / '.erixpo/bin/erixpo').exists())

    def test_legacy_uninstall_preserves_memory(self):
        self.legacy_install('615961e')
        (self.target / '.erixpo/MEMORY.md').write_text('keep memory')
        self.install('--uninstall')
        self.assertFalse((self.target / 'bin/erixpo').exists())
        self.assertFalse((self.target / '.agents/skills/erixpo').exists())
        self.assertEqual((self.target / '.erixpo/MEMORY.md').read_text(), 'keep memory')

    def test_reinstall_and_host_expansion(self):
        self.install()
        self.install('--host', 'claude')
        self.assertTrue(os.access(self.target / '.erixpo/bin/erixpo', os.X_OK))
        self.assertTrue((self.target / '.claude/skills/erixpo/SKILL.md').is_file())
        self.assertTrue((self.target / '.agents/skills/erixpo/SKILL.md').is_file())
        self.install('--uninstall')
        self.assertFalse((self.target / 'bin').is_symlink())
        self.assertFalse((self.target / '.erixpo').exists())

    def test_dry_run_does_not_create_target_or_modify_install(self):
        self.target.rmdir()
        self.install('--dry-run')
        self.assertFalse(self.target.exists())
        self.install()
        before = self.snapshot()
        self.install('--uninstall', '--purge', '--purge-docs', '--dry-run')
        self.assertEqual(before, self.snapshot())

    def test_unrelated_scripts_and_existing_bin_are_preserved(self):
        (self.target / 'scripts').mkdir()
        (self.target / 'scripts/worktree.sh').write_text('user script')
        (self.target / 'bin').mkdir()
        (self.target / 'bin/mine').write_text('my tool')
        self.install()
        self.assertEqual((self.target / 'scripts/worktree.sh').read_text(), 'user script')
        result = subprocess.run([str(self.target / 'bin/erixpo'), '--help'], capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.install('--uninstall')
        self.assertEqual((self.target / 'bin/mine').read_text(), 'my tool')

    def test_collision_preflight_and_modified_file_uninstall(self):
        (self.target / '.erixpo/bin').mkdir(parents=True)
        cli = self.target / '.erixpo/bin/erixpo'
        cli.write_text('unrelated')
        before = self.snapshot()
        self.install(ok=False)
        self.assertEqual(before, self.snapshot())
        cli.unlink()
        self.install()
        cli.write_text('customized')
        self.install(ok=False)
        self.install('--uninstall')
        self.assertEqual(cli.read_text(), 'customized')
        metadata = json.loads((self.target / '.erixpo/install-manifest.json').read_text())
        self.assertIn('.erixpo/bin/erixpo', metadata['files'])

    def test_symlink_parent_and_foreign_compat_link(self):
        outside = self.base / 'outside'
        outside.mkdir()
        (self.target / '.agents').symlink_to(outside, target_is_directory=True)
        self.install(ok=False)
        self.assertEqual(list(outside.iterdir()), [])
        (self.target / '.agents').unlink()
        (self.target / 'bin').symlink_to(outside, target_is_directory=True)
        self.install()
        self.assertEqual(os.readlink(self.target / 'bin'), str(outside))
        self.install('--uninstall')
        self.assertTrue((self.target / 'bin').is_symlink())

    def test_global_install_uninstall_never_touches_target(self):
        home = self.base / 'home'
        home.mkdir()
        env = dict(os.environ, HOME=str(home))
        self.install('--global', env=env)
        self.assertEqual(list(self.target.iterdir()), [])
        self.assertTrue((home / '.agents/skills/erixpo/SKILL.md').exists())
        self.install('--global', '--uninstall', env=env)
        self.assertEqual(list(self.target.iterdir()), [])
        self.assertEqual(list(home.iterdir()), [])

    def test_purge_docs_obeys_file_manifest(self):
        (self.target / '.erixpo').mkdir()
        (self.target / 'documents').mkdir()
        (self.target / 'AGENTS.md').write_text('mine')
        (self.target / 'documents/mine.md').write_text('mine')
        (self.target / 'documents/generated.md').write_text('generated')
        (self.target / '.erixpo/init-manifest.txt').write_text('documents/generated.md\ndocuments\n')
        self.install('--purge-docs')
        self.assertTrue((self.target / 'AGENTS.md').exists())
        self.assertTrue((self.target / 'documents/mine.md').exists())
        self.assertFalse((self.target / 'documents/generated.md').exists())

    def test_purge_removes_memory_but_preserves_extras_and_worktree_bookkeeping(self):
        self.install()
        for name in ['MEMORY.md', 'USER.md', 'loop.log', 'worktrees.jsonl', 'unrelated.txt']:
            (self.target / '.erixpo' / name).write_text('content')
        self.install('--purge')
        for name in ['MEMORY.md', 'USER.md', 'loop.log']:
            self.assertFalse((self.target / '.erixpo' / name).exists())
        for name in ['worktrees.jsonl', 'unrelated.txt']:
            self.assertTrue((self.target / '.erixpo' / name).exists())

    def test_unowned_metadata_collision_does_not_write(self):
        (self.target / '.erixpo').mkdir()
        (self.target / '.erixpo/install-manifest.txt').write_text('my file')
        before = self.snapshot()
        self.install(ok=False)
        self.assertEqual(before, self.snapshot())

    def test_modified_hashed_document_is_retained(self):
        import hashlib
        (self.target / '.erixpo').mkdir()
        (self.target / 'generated.md').write_text('changed')
        manifest = self.target / '.erixpo/init-manifest.txt'
        manifest.write_text(hashlib.sha256(b'original').hexdigest() + '\tgenerated.md\n')
        self.install('--purge-docs')
        self.assertTrue((self.target / 'generated.md').exists())
        self.assertTrue(manifest.exists())

    def test_failed_write_rolls_back_complete_target(self):
        self.install()
        before = self.snapshot()
        original = installer.os.replace
        count = 0

        def fail_once(*args):
            nonlocal count
            count += 1
            if count == 8:
                raise OSError('injected write failure')
            return original(*args)

        from argparse import Namespace
        options = Namespace(source=str(ROOT), target=str(self.target), globally=False, detect=False,
                            host='claude', uninstall=False, purge=False, purge_docs=False,
                            purge_worktrees=False, dry_run=False, expand=False)
        with patch.object(installer.os, 'replace', side_effect=fail_once):
            with self.assertRaisesRegex(OSError, 'injected'):
                installer.run(options)
        self.assertEqual(before, self.snapshot())

    def test_dirty_worktree_purge_refuses_deletion(self):
        def git(*args):
            return subprocess.run(['git', '-C', str(self.target), *args], capture_output=True, text=True, check=True)
        git('init', '-q')
        git('config', 'user.email', 'test@example.invalid')
        git('config', 'user.name', 'Test')
        (self.target / 'readme').write_text('base')
        (self.target / '.gitignore').write_text('unsaved\n')
        git('add', '.')
        git('commit', '-qm', 'base')
        result = subprocess.run(['python3', str(ROOT / 'scripts/worktree-state.py'), 'isolate', '--porcelain'], cwd=self.target, text=True, capture_output=True, check=True)
        wt = Path(dict(line.split('=', 1) for line in result.stdout.splitlines())['path'])
        (wt / 'unsaved').write_text('keep')
        before = self.snapshot()
        self.install('--purge-worktrees', '--dry-run')
        self.assertEqual(before, self.snapshot())
        self.install('--purge-worktrees', ok=False)
        self.assertEqual((wt / 'unsaved').read_text(), 'keep')


if __name__ == '__main__':
    unittest.main()
