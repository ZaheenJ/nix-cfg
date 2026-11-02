import json
from pathlib import Path
import stat
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import tomlkit

import merge_settings


class MergeSettingsTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.directory = Path(directory.name)
        self.declared = {
            "codex": {"nixos": {"command": "mcp-nixos", "args": ["--stdio"]}},
            "antigravity": {"editorMode": "vim", "nested": {"declared": True}},
        }

    def config_path(self, kind):
        return self.directory / kind / ("config.toml" if kind == "codex" else "settings.json")

    def seed(self, kind, content):
        path = self.config_path(kind)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        path.chmod(0o640)
        return path

    def run_merger(self, kind, path):
        return subprocess.run(
            [
                sys.executable,
                merge_settings.__file__,
                kind,
                str(path),
                json.dumps(self.declared[kind]),
            ],
            capture_output=True,
            text=True,
        )

    def test_invalid_settings_report_failure_without_modifying_file(self):
        cases = {
            "codex": [
                "model = [\n",
                'mcp_servers = "broken"\n',
                '[mcp_servers]\nnixos = "broken"\n',
            ],
            "antigravity": [
                '{"broken":',
                "null",
                "false",
                "[]",
                "42",
                '{"editorMode": NaN}',
                '{"editorMode": Infinity}',
                '{"custom": 1e999}',
            ],
        }
        for kind, contents in cases.items():
            for content in contents:
                with self.subTest(kind=kind, content=content):
                    path = self.seed(kind, content)
                    before = path.stat()
                    result = self.run_merger(kind, path)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn(str(path), result.stderr)
                    self.assertIn("Existing configuration was not replaced", result.stderr)
                    self.assertEqual(path.read_bytes(), content.encode())
                    self.assertEqual(path.stat().st_mtime_ns, before.st_mtime_ns)
                    self.assertEqual(path.stat().st_mode, before.st_mode)
                    self.assertEqual(list(path.parent.iterdir()), [path])

    def test_missing_empty_and_whitespace_files_initialize_privately(self):
        for kind in self.declared:
            for content in (None, "", " \n\t"):
                with self.subTest(kind=kind, content=content):
                    path = self.config_path(kind)
                    path.unlink(missing_ok=True)
                    if content is not None:
                        self.seed(kind, content)
                    result = self.run_merger(kind, path)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o600)
                    text = path.read_text()
                    if kind == "codex":
                        self.assertEqual(tomlkit.parse(text)["mcp_servers"], self.declared[kind])
                    else:
                        self.assertEqual(json.loads(text), self.declared[kind])

    def test_codex_preserves_comments_and_unrelated_settings(self):
        path = self.seed(
            "codex",
            '# Keep this comment\nmodel = "custom"\n'
            '[mcp_servers.nixos]\ncommand = "old"\nenabled = false\n'
            '[mcp_servers.personal]\ncommand = "personal-server"\n',
        )
        merge_settings.merge_settings("codex", path, self.declared["codex"])
        text = path.read_text()
        doc = tomlkit.parse(text)
        self.assertIn("# Keep this comment", text)
        self.assertEqual(doc["model"], "custom")
        self.assertEqual(doc["mcp_servers"]["nixos"]["command"], "mcp-nixos")
        self.assertFalse(doc["mcp_servers"]["nixos"]["enabled"])
        self.assertEqual(doc["mcp_servers"]["personal"]["command"], "personal-server")
        merge_settings.merge_settings("codex", path, self.declared["codex"])
        self.assertEqual(path.read_text(), text)

    def test_antigravity_preserves_unrelated_and_nested_settings(self):
        path = self.seed(
            "antigravity",
            '{"editorMode":"old","custom":"saved","nested":{"saved":true}}',
        )
        merge_settings.merge_settings("antigravity", path, self.declared["antigravity"])
        self.assertEqual(
            json.loads(path.read_text()),
            {
                "editorMode": "vim",
                "custom": "saved",
                "nested": {"saved": True, "declared": True},
            },
        )

    def test_invalid_symlinks_and_targets_remain_untouched(self):
        for kind in self.declared:
            with self.subTest(kind=kind):
                target = self.directory / f"{kind}-target"
                target.write_text("invalid [")
                target.chmod(0o440)
                path = self.config_path(kind)
                path.parent.mkdir()
                path.symlink_to(target)
                result = self.run_merger(kind, path)
                self.assertNotEqual(result.returncode, 0)
                self.assertTrue(path.is_symlink())
                self.assertEqual(path.readlink(), target)
                self.assertEqual(target.read_text(), "invalid [")
                self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o440)

    def test_valid_symlinks_become_private_files_without_changing_targets(self):
        for kind in self.declared:
            with self.subTest(kind=kind):
                target = self.directory / f"{kind}-target"
                target.write_text("")
                target.chmod(0o440)
                path = self.config_path(kind)
                path.parent.mkdir()
                path.symlink_to(target)
                result = self.run_merger(kind, path)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertFalse(path.is_symlink())
                self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o600)
                self.assertEqual(target.read_text(), "")
                self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o440)

    def test_dangling_symlink_is_preserved(self):
        for kind in self.declared:
            with self.subTest(kind=kind):
                path = self.config_path(kind)
                path.parent.mkdir()
                target = self.directory / "missing"
                path.symlink_to(target)
                result = self.run_merger(kind, path)
                self.assertNotEqual(result.returncode, 0)
                self.assertTrue(path.is_symlink())
                self.assertEqual(path.readlink(), target)
                self.assertFalse(target.exists())

    def test_write_failures_preserve_original_and_remove_temporary_file(self):
        for kind in self.declared:
            for operation in ("fsync", "replace"):
                with self.subTest(kind=kind, operation=operation):
                    path = self.seed(kind, "")
                    with patch.object(merge_settings.os, operation, side_effect=OSError("disk error")):
                        with self.assertRaises(OSError):
                            merge_settings.merge_settings(kind, path, self.declared[kind])
                    self.assertEqual(path.read_bytes(), b"")
                    self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o640)
                    self.assertEqual(list(path.parent.iterdir()), [path])


if __name__ == "__main__":
    unittest.main()
