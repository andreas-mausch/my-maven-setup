"""Standard-library regression tests, optionally against the extracted build artifact."""

import contextlib
import datetime as dt
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.dont_write_bytecode = True
default_validator = Path(__file__).resolve().parents[2] / "main/resources/de/neonew/maven/prepare-container-exceptions.py"
spec = importlib.util.spec_from_file_location("validator", os.environ.get("CONTAINER_EXCEPTIONS_VALIDATOR", default_validator))
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


class ContainerExceptionsTest(unittest.TestCase):
    now = dt.datetime(2026, 11, 18, 12, tzinfo=dt.timezone.utc)

    def entry(self, **changes):
        return {"cve": "CVE-2026-1234", "expires": "2026-12-02", "reason": "Approved", **changes}

    def test_scopes_and_escaping(self):
        entries = [self.entry(reason='Approved <risk> "quoted"\nWith detail'),
                   self.entry(package="libssl3", version="3.5.9-r0"),
                   {"package": "libcrypto3", "version": "3.5.9-r0", "expires": "2026-12-02", "reason": "Approved"}]
        rules = validator.validate({"exceptions": entries}, self.now)["ignore"]
        self.assertNotIn("package", rules[0])
        self.assertEqual(rules[1]["package"], {"name": "^libssl3$", "version": "3.5.9-r0", "type": "apk"})
        self.assertNotIn("vulnerability", rules[2])
        self.assertEqual(json.loads(json.dumps(rules)), rules)

    def test_invalid_rules(self):
        invalid = [42, self.entry(cve="bad"), self.entry(cve=""), self.entry(reason=" \n\t"),
                   self.entry(reason=42), self.entry(expires=dt.date(2026, 12, 2)),
                   self.entry(expires="2026-02-30"), self.entry(expires="20261202"),
                   self.entry(expires="2026-11-18"), self.entry(expires="2026-12-19"),
                   self.entry(expires=""), self.entry(typo="x"), self.entry(version="1.0"),
                   self.entry(package="libssl3"), self.entry(package="libssl3", version="*"),
                   self.entry(package="libssl3.*", version="3.5.9-r0"), self.entry(cve="CVE-2026-1234\n")]
        for entry in invalid:
            with self.subTest(entry=entry), self.assertRaises(validator.ValidationError):
                validator.validate({"exceptions": [entry]}, self.now)
        for source in [{}, {"other": []}, {"exceptions": [], "other": []}, {"exceptions": {}}]:
            with self.subTest(source=source), self.assertRaises(validator.ValidationError):
                validator.validate(source, self.now)

    def test_expiry_boundaries(self):
        midnight = self.now.replace(hour=0)
        self.assertEqual(len(validator.validate({"exceptions": [self.entry(expires="2026-12-18")]}, midnight)["ignore"]), 1)
        with self.assertRaises(validator.ValidationError):
            validator.validate({"exceptions": [self.entry(expires="2026-12-19")]}, midnight)

    def test_empty_and_audit_outputs(self):
        with tempfile.TemporaryDirectory() as work:
            source = Path(work) / "input.toml"
            output = Path(work) / "custom build/config.yaml"
            source.write_text("exceptions = []\n", encoding="utf-8")
            self.assertTrue(validator.prepare(source, output))
            self.assertEqual(json.loads(output.read_text()), {"ignore": []})
            self.assertEqual((output.parent / "container-vulnerability-exceptions.toml").read_bytes(), source.read_bytes())

    def test_scan_and_exit_codes(self):
        with tempfile.TemporaryDirectory() as work:
            source = Path(work) / "input.toml"
            output = Path(work) / "config.yaml"
            source.write_text("exceptions = []\n", encoding="utf-8")
            with patch.object(validator.subprocess, "run", return_value=subprocess.CompletedProcess([], 2)) as run:
                self.assertEqual(validator.main(["--scan", str(source), str(output), "sbom:path with spaces", "--fail-on", "high"]), 2)
                self.assertEqual(run.call_args.args[0], ["grype", "--config", str(output), "sbom:path with spaces", "--fail-on", "high"])
            source.unlink()
            # An existing generated configuration must not be applied when input is absent.
            with patch.object(validator.subprocess, "run", return_value=subprocess.CompletedProcess([], 0)) as run:
                self.assertEqual(validator.main(["--scan", str(source), str(output), "source"]), 0)
                self.assertEqual(run.call_args.args[0], ["grype", "source"])

    def test_invalid_input_does_not_scan_or_overwrite(self):
        with tempfile.TemporaryDirectory() as work:
            source = Path(work) / "input.toml"
            output = Path(work) / "config.yaml"
            output.write_text("previous", encoding="utf-8")
            for text in ["exceptions = [", 'exceptions = [{ reason = "Unscoped" }]']:
                source.write_text(text, encoding="utf-8")
                with patch.object(validator.subprocess, "run") as run, contextlib.redirect_stderr(io.StringIO()):
                    self.assertEqual(validator.main(["--scan", str(source), str(output)]), 1)
                    run.assert_not_called()
                self.assertEqual(output.read_text(), "previous")


if __name__ == "__main__":
    unittest.main()
