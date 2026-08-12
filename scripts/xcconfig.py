#!/usr/bin/env python3

"""Resolve one value from the simple xcconfig files used by Apple Libc."""

import argparse
import re
from pathlib import Path


REFERENCE = re.compile(r"\$\(([^$()]*)\)")


def assignments(path, seen=()):
    if path in seen:
        raise ValueError(f"recursive xcconfig include: {path}")
    values = {}
    for line in path.read_text().splitlines():
        line = line.split("//", 1)[0].strip()
        if line.startswith("#include"):
            include = line.split('"', 2)[1]
            include_path = path.parent / include
            if include_path.exists():
                values.update(assignments(include_path, seen + (path,)))
            continue
        if not line or line.startswith("#") or "=" not in line:
            continue
        name, value = line.split("=", 1)
        values[name.strip()] = value.strip()
    return values


def resolve(value, values, stack=()):
    def replace(match):
        name = resolve(match.group(1), values, stack)
        if name in stack:
            raise ValueError(f"recursive xcconfig variable: {name}")
        return resolve(values.get(name, ""), values, stack + (name,))

    previous = None
    while value != previous:
        previous = value
        value = REFERENCE.sub(replace, value)
    return " ".join(value.split())


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("xcconfig", type=Path)
    parser.add_argument("name")
    parser.add_argument("overrides", nargs="*")
    arguments = parser.parse_args()

    values = assignments(arguments.xcconfig)
    for override in arguments.overrides:
        name, value = override.split("=", 1)
        values[name] = value
    print(resolve(values.get(arguments.name, ""), values))


if __name__ == "__main__":
    main()
