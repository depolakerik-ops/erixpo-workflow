import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

PACK = Path(__file__).resolve().parents[1]


class AdapterContracts(unittest.TestCase):
    def test_provider_invocation_and_exit_propagation(self):
        binaries = {"claude": "claude", "codex": "codex", "cursor": "agent", "gemini": "gemini", "hermes": "hermes", "opencode": "opencode"}
        with tempfile.TemporaryDirectory(prefix="erixpo adapter ") as directory:
            root = Path(directory)
            toolbin = root / "tools"
            toolbin.mkdir()
            prompt = root / "prompt.txt"
            prompt.write_text('A multiline\nprompt with "quotes" and $literal')
            result = root / "result.json"
            for adapter, binary in binaries.items():
                with self.subTest(adapter=adapter):
                    exe = toolbin / binary
                    exe.write_text('#!/usr/bin/env python3\nimport os,sys,json\nfrom pathlib import Path\nPath(os.environ["RESULT"]).write_text(json.dumps({"argv":sys.argv[1:],"cwd":os.getcwd(),"prompt":os.environ["ERIXPO_PROMPT_FILE"],"iteration":os.environ["ERIXPO_ITERATION"]}))\nsys.exit(7)\n')
                    exe.chmod(0o755)
                    env = dict(os.environ, PATH=str(toolbin) + os.pathsep + os.environ["PATH"], RESULT=str(result))
                    out = subprocess.run(["bash", str(PACK / "adapters" / (adapter + ".sh")), str(root), str(prompt), "3"], env=env, capture_output=True, text=True)
                    self.assertEqual(out.returncode, 7, out.stderr)
                    data = json.loads(result.read_text())
                    self.assertEqual(Path(data["cwd"]).resolve(), root.resolve())
                    self.assertIn(prompt.read_text(), data["argv"])
                    self.assertEqual(data["prompt"], str(prompt))
                    self.assertEqual(data["iteration"], "3")

    def test_generic_command_receives_contract(self):
        with tempfile.TemporaryDirectory() as directory:
            env = dict(os.environ, ERIXPO_WORKER_CMD='test "$ERIXPO_ITERATION" = 4 && test "$ERIXPO_ROOT" = "$PWD" && test -f "$ERIXPO_PROMPT_FILE"')
            prompt = Path(directory) / "prompt"
            prompt.write_text("hello")
            self.assertEqual(subprocess.call(["bash", str(PACK / "adapters/generic.sh"), directory, str(prompt), "4"], env=env), 0)
