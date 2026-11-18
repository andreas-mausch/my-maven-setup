"""Real Grype matching and HTML rendering; standard libraries only, Python >= 3.11.

Uses an isolated vulnerable SBOM, never the application image's enforcement inputs.
"""

import datetime as dt
import json
from pathlib import Path
import subprocess
import sys


def main():
    if len(sys.argv) != 4:
        raise SystemExit("Usage: container_exceptions_integration_test.py EXTRACTED_RESOURCES TEST_OUTPUT EXCEPTION_FIXTURE")
    resources, output, fixture = map(Path, sys.argv[1:])
    output.mkdir(parents=True, exist_ok=True)
    expiry = (dt.datetime.now(dt.timezone.utc).date() + dt.timedelta(days=14)).isoformat()
    source = output / "exceptions.toml"
    source.write_text(fixture.read_text(encoding="utf-8").replace("YYYY-MM-DD", expiry), encoding="utf-8")
    sbom = output / "vulnerable.cdx.json"
    sbom.write_text(json.dumps({"bomFormat": "CycloneDX", "specVersion": "1.6", "version": 1,
                               "components": [{"type": "library", "name": "log4j-core", "version": "2.14.1",
                                               "purl": "pkg:maven/org.apache.logging.log4j/log4j-core@2.14.1"}]}), encoding="utf-8")
    baseline = output / "baseline.json"
    accepted = output / "accepted.json"
    report = output / "accepted.html"
    subprocess.run(["grype", f"sbom:{sbom}", "--by-cve", "--output", "json", "--file", str(baseline)], check=True)
    subprocess.run([sys.executable, str(resources / "prepare-container-exceptions.py"), "--scan",
                    str(source), str(output / "exceptions.grype.yaml"), f"sbom:{sbom}", "--by-cve",
                    "--output", f"json={accepted}", "--output", f"template={report}",
                    "--template", str(resources / "vulnerability-report.tmpl"),
                    "--name", f"CI exception fixture\ttest\t{dt.datetime.now(dt.timezone.utc).date()}"], check=True)

    def matches(path, key):
        return [match for match in json.loads(path.read_text(encoding="utf-8"))[key]
                if match["vulnerability"]["id"] == "CVE-2021-44228"]

    assert len(matches(baseline, "matches")) == 1
    assert not matches(accepted, "matches")
    assert len(matches(accepted, "ignoredMatches")) == 1
    html = report.read_text(encoding="utf-8")
    assert "Accepted findings (1)" in html
    assert "&lt;not an application approval&gt;" in html
    assert source.read_bytes() == (output / "container-vulnerability-exceptions.toml").read_bytes()
    print("Real Grype exception matching and Accepted report tests passed.")


if __name__ == "__main__":
    main()
