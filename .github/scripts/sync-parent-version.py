#!/usr/bin/env python3

import argparse
import xml.etree.ElementTree as ET
from pathlib import Path


MAVEN_NAMESPACE = "http://maven.apache.org/POM/4.0.0"
ET.register_namespace("", MAVEN_NAMESPACE)


def child(element: ET.Element, name: str) -> ET.Element | None:
    return element.find(f"{{{MAVEN_NAMESPACE}}}{name}")


def required_text(element: ET.Element, name: str, pom: Path) -> str:
    value = child(element, name)
    if value is None or value.text is None or not value.text.strip():
        raise ValueError(f"{pom}: missing {name}")
    return value.text.strip()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("pom", type=Path)
    args = parser.parse_args()

    fixture_tree = ET.parse(args.pom)
    fixture_parent = child(fixture_tree.getroot(), "parent")
    if fixture_parent is None:
        raise ValueError(f"{args.pom}: missing parent")

    relative_path = required_text(fixture_parent, "relativePath", args.pom)
    parent_pom = (args.pom.parent / relative_path).resolve()
    parent_project = ET.parse(parent_pom).getroot()

    for coordinate in ("groupId", "artifactId"):
        expected = required_text(fixture_parent, coordinate, args.pom)
        actual = required_text(parent_project, coordinate, parent_pom)
        if actual != expected:
            raise ValueError(f"{args.pom}: parent {coordinate} is {expected}, but {parent_pom} declares {actual}")

    fixture_version = child(fixture_parent, "version")
    if fixture_version is None:
        raise ValueError(f"{args.pom}: missing parent version")

    expected_version = required_text(parent_project, "version", parent_pom)
    actual_version = (fixture_version.text or "").strip()
    if actual_version != expected_version:
        fixture_version.text = expected_version
        fixture_tree.write(args.pom, encoding="unicode")
        print(f"{args.pom}: parent version {actual_version} -> {expected_version}")


if __name__ == "__main__":
    main()
