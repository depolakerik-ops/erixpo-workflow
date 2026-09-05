"""Public CLI journey routing from a fresh installation, not source imports."""
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class JourneyTests(unittest.TestCase):
    def test_installed_request_routing_and_research_depth(self):
        with tempfile.TemporaryDirectory(prefix='erixpo journeys ') as directory:
            target = Path(directory)
            result = subprocess.run(['bash', str(ROOT / 'install.sh'), '--target', directory, '--host', 'generic'], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            cli = target / '.erixpo/bin/erixpo'
            cases = [
                ('Fix the login crash', 'fix', [], 'skip'),
                ('Add a CSV export feature', 'feature', ['--memory-hit'], 'skip'),
                ('Implement offline sync support', 'feature', ['--large-change', '--memory-hit'], 'full'),
                ('Create a simple HTML website', 'new', [], 'full'),
                ('Build a responsive website with a sidebar', 'new', [], 'full'),
                ('Build a new macOS app for personal notes', 'new', [], 'full'),
                ('Create an Android app', 'new', [], 'full'),
                ('Build a Go CLI', 'new', [], 'full'),
                ('Build a robot controller', 'new', [], 'full'),
                ('Create a Blender 3D animation', 'new', [], 'full'),
                ('Build a Flutter app', 'new', [], 'full'),
                ('Build a React Native app', 'new', [], 'full'),
                ('Build a Linux desktop app', 'new', [], 'full'),
                ('Fix the API error', 'fix', ['--unknown-api'], 'narrow'),
            ]
            for prompt, route, flags, depth in cases:
                with self.subTest(prompt=prompt):
                    result = subprocess.run([str(cli), 'classify', prompt], cwd=target, capture_output=True, text=True)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(result.stdout.splitlines()[0], 'request_class: ' + route)
                    result = subprocess.run([str(cli), 'research-scope', '--class', route, *flags], cwd=target, capture_output=True, text=True)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(result.stdout.strip(), depth)


if __name__ == '__main__':
    unittest.main()
