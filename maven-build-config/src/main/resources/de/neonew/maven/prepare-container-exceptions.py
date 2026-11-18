"""Validate optional TOML exceptions and prepare Grype configuration (Python >= 3.11).

Uses only standard libraries. JSON output is valid YAML and is accepted by Grype.
Usage: python prepare-container-exceptions.py [--scan] INPUT OUTPUT [GRYPE_ARGUMENTS...]
"""

import datetime as dt
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import tomllib


class ValidationError(ValueError):
    """An exception does not meet the risk acceptance policy."""


def validate(source, now):
    if set(source) != {"exceptions"}:
        raise ValidationError("Only the exceptions table key is allowed.")
    entries = source["exceptions"]
    if not isinstance(entries, list):
        raise ValidationError("exceptions must be an array.")
    rules = []
    for index, entry in enumerate(entries):
        if not isinstance(entry, dict):
            raise ValidationError(f"Exception {index} must be a table.")
        if set(entry) - {"cve", "package", "version", "expires", "reason"}:
            raise ValidationError(f"Unknown exception field in entry {index}.")
        if any(not isinstance(value, str) for value in entry.values()):
            raise ValidationError("Exception fields must be strings (quote dates).")
        cve = entry.get("cve", "")
        package = entry.get("package", "")
        version = entry.get("version", "")
        reason = entry.get("reason", "")
        until = entry.get("expires", "")
        if not reason.strip():
            raise ValidationError("An exception reason is required.")
        if cve and not re.fullmatch(r"CVE-[0-9]{4}-[0-9]{4,}", cve):
            raise ValidationError(f"Invalid CVE identifier: {cve}")
        if not package:
            if version or not cve:
                raise ValidationError("Specify a CVE or an exact APK package version; unscoped exceptions are forbidden.")
        else:
            if not re.fullmatch(r"[a-z0-9][a-z0-9_-]*", package):
                raise ValidationError(f"Invalid APK package name: {package}")
            if not re.fullmatch(r"[0-9][0-9A-Za-z._+~-]*", version):
                raise ValidationError(f"Invalid exact APK version: {version}")
        try:
            if not re.fullmatch(r"[0-9]{4}-[0-9]{2}-[0-9]{2}", until):
                raise ValueError("Expected YYYY-MM-DD")
            expiry = dt.datetime.combine(dt.date.fromisoformat(until), dt.time(), dt.timezone.utc)
        except ValueError as error:
            raise ValidationError(f"Invalid UTC date: {until}") from error
        if expiry <= now:
            raise ValidationError(f"Expired container exception: {cve} {package}@{version} ({until} UTC).")
        if expiry > now + dt.timedelta(days=30):
            raise ValidationError(f"Exception expiry must be at most 30 days in the future: {until}.")
        rule = {"reason": f"{reason}\nExpires: {until} (UTC)."}
        if cve:
            rule["vulnerability"] = cve
        if package:
            rule["package"] = {"name": f"^{package}$", "version": version, "type": "apk"}
        rules.append(rule)
    return {"ignore": rules}


def prepare(input_path, output_path):
    # A dangling symlink is invalid, not an absent optional input.
    if not input_path.exists() and not input_path.is_symlink():
        return False
    with input_path.open("rb") as stream:
        configuration = validate(tomllib.load(stream), dt.datetime.now(dt.timezone.utc))
    audit_path = output_path.parent / "container-vulnerability-exceptions.toml"
    if input_path.resolve() in {output_path.resolve(), audit_path.resolve()}:
        raise ValidationError("Keep exception outputs separate from the input file.")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    # Publish only a completely validated configuration, with atomic replacement.
    with tempfile.TemporaryDirectory(dir=output_path.parent) as work:
        result = Path(work) / "configuration.json"
        result.write_text(json.dumps(configuration, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        audit = Path(work) / "input.toml"
        shutil.copyfile(input_path, audit)
        os.replace(result, output_path)
        os.replace(audit, audit_path)
    if configuration["ignore"]:
        print(f"WARNING: {len(configuration['ignore'])} explicitly approved container vulnerability exception(s) are active.", file=sys.stderr)
        print(json.dumps(configuration, ensure_ascii=False, indent=2))
    return True


def main(arguments=None):
    arguments = list(sys.argv[1:] if arguments is None else arguments)
    scan = bool(arguments and arguments[0] == "--scan")
    if scan:
        arguments.pop(0)
    if len(arguments) < 2:
        print("Usage: prepare-container-exceptions.py [--scan] INPUT OUTPUT [GRYPE_ARGUMENTS...]", file=sys.stderr)
        return 1
    input_path, output_path = map(Path, arguments[:2])
    try:
        prepared = prepare(input_path, output_path)
        if scan:
            command = ["grype"]
            if prepared:
                command += ["--config", str(output_path)]
            result = subprocess.run(command + arguments[2:], check=False)
            return result.returncode if result.returncode >= 0 else 128 - result.returncode
        return 0
    except (ValidationError, tomllib.TOMLDecodeError, OSError) as error:
        print(str(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
